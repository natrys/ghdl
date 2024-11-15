(import xtract)
(import httpx)
(import asyncio)
(import platform)

(import fnmatch [fnmatch] os re shutil traceback sys time)
(import ghdl.config :as config
        ghdl.remote :as remote
        ghdl.local :as local
        ghdl.utils :as utils)

(require hyrule [as-> -> unless])

(setv records config.packages)
(setv Config config.Config)
(setv local-db (local.LocalRecord))


(defn file-select [glob]
  (for [[root dir files] (os.walk ".")]
    (for [file files]
      (setv fullpath (os.path.join root file))
      (setv isApp? (utils.isExecutable? fullpath))
      (when (and (fnmatch file glob) isApp?)
        (return fullpath)))))


(defn url-select [asset-filter url_data]
  (defn run-filter [f]
    (for [[asset url] url_data]
      (when (f asset)
        (return url))))

  (if (isinstance asset-filter str)
      (do
        (setv pattern (re.compile asset-filter re.IGNORECASE))
        (run-filter (fn [name] (bool (re.search pattern name)))))
      (run-filter asset-filter)))


(defn :async add-remote-metadata [record client]
  (setv record.url None)

  (setv remote-metadata
        (try
          (await (remote.metadata record client Config.token))
          (except [e []]
            (print f"Failed to fetch remote data from Github API for {record.repo}")
            (print (traceback.format_exc))
            (setv record.toUpdate? False)
            (.append Config.failures #(record.repo "Network"))
            (return))))

  (setv record.tag remote-metadata.tag)
  (setv record.timestamp remote-metadata.timestamp)

  (setv dl-url (url-select record.asset-filter remote-metadata.url_data))
  (if (not dl-url)
      (do
        (setv record.toUpdate? False)
        (.append Config.failures #(record.repo "No Matching URL"))
        (return))
      (setv record.url dl-url)))


(defn add-local-metadata [record]
  (setv local (local-db.fetch-row record.repo))
  (when local
    (setv record.exists? True)
    (when (and record.toUpdate? (<= record.timestamp local.timestamp))
      (setv record.toUpdate? False))))


(defn skip-single [repo]
  (as-> Config.single it
        (and it (!= repo it))))


(defn :async fetch-remote-local-metadata [records]
  (setv limits (httpx.Limits :max_connections 10))
  (with [:async client (httpx.AsyncClient :base_url "https://api.github.com/repos/"
                                          :limits limits
                                          :follow_redirects True)]
    (await
      (asyncio.gather
        #*(gfor record records (fetch-remote-local-metadata-1 record client))
        :return_exceptions True))))


(defn :async fetch-remote-local-metadata-1 [record client]
  (when (skip-single record.repo) (return))
  (when (and record.pin (not (= (platform.machine) record.pin))) (return))

  (await (add-remote-metadata record client))
  (add-local-metadata record)
  (record.pretty))


(defn process-loop [records]
  (for [record records]
    (when (skip-single record.repo) (continue))
    (when (and record.pin (not (= (platform.machine) record.pin))) (continue))

    (when record.toUpdate?
      (try
        (process record)
        (except [e []]
          (print f"Failed to process {record.repo}")
          (print (traceback.format_exc)))))))


(defn process [record]
  (unless record.toUpdate? (return))

  (with [(utils.Tempdir)]
    (setv filename (-> record.url (.split "/") (get -1)))
    (utils.download_file record.url filename)

    (when (and record.isArchive? (utils.isArchive? filename))
      (when (.endswith filename ".deb")
        (os.system f"ar x {filename} >/dev/null 2>&1")
        (os.remove "debian-binary")
        (os.remove "control.tar.xz")
        (os.remove filename)
        (setv filename "data.tar.xz"))
      (xtract.xtract filename :all True)
      (os.remove filename)
      (setv filename (file-select record.basename-glob)))

    (shutil.move filename record.name)
    (utils.make-executable record.name)
    (when record.strip? (os.system f"strip {record.name} 2>/dev/null"))

    (setv destination (os.path.join Config.location record.name))
    (shutil.move record.name destination)
    (if record.exists?
        (local-db.update-row record.repo record.timestamp)
        (local-db.add-row record.repo record.timestamp))))


(defn set-dry []
  (setv Config.dry-run True))


;; If a repo is deleted from config, then running this just deletes entry from DB
(defn set-single [repo]
  (local-db.delete-row repo)
  (setv Config.single repo))


(defn main []
  (asyncio.run (fetch-remote-local-metadata records))
  (unless Config.dry-run (process-loop records))
  (for [#(repo reason) Config.failures]
    (print f"Failed: https://github.com/{repo} ({reason})"))
  (local-db.finalise))
