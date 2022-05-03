(import xtract)
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
      (if (f asset)
          (return url))))
  
  (if (isinstance asset-filter str)
      (do
        (setv pattern (re.compile asset-filter re.IGNORECASE))
        (run-filter (fn [name] (bool (re.search pattern name)))))
      (run-filter asset-filter)))


(defn add-remote-metadata [record]
  (setv remote-metadata
        (remote.metadata record.repo record.pre-release? Config.token))

  ;; Network error
  (when (not remote-metadata)
    (do
      (setv record.toUpdate? False)
      (.append Config.failures (, record.repo "Network"))
      (return)))

  (setv dl-url (url-select record.asset-filter remote-metadata.url_data))

  ;; User filter couldn't find any candidate
  (when (not dl-url)
      (do
        (setv record.toUpdate? False)
        (setv record.url "N/A")
        (.append Config.failures (, record.repo "No Matching URL"))
        (return)))

  (setv record.url dl-url)
  (setv record.tag remote-metadata.tag)
  (setv record.timestamp remote-metadata.timestamp))


(defn add-local-metadata [record]
  (setv local (local-db.fetch-row record.repo))
  (when local
    (setv record.exists? True)
    (if (<= record.timestamp local.timestamp)
        (setv record.toUpdate? False))))


(defn check-single [repo]
  (as-> Config.single it
    (and it (!= repo it))))


(defn fetch-remote-local-metadata [records]
  (for [record records]
    (when (check-single record.repo) (continue))
    (when (and record.pin (not (= (platform.machine) record.pin))) (continue))

    (add-remote-metadata record)
    ;; rate limiting can't hurt
    (time.sleep Config.sleep)
    (add-local-metadata record)
    (record.pretty)))


(defn process-loop [records]
  (for [record records]
    (when (check-single record.repo) (continue))
    (when (and record.pin (not (= (platform.machine) record.pin))) (continue))

    (when record.toUpdate?
      (try
        (process record)
        (except [e []]
          (print f"Failed to process {record.repo}")
          (print (traceback.format_exc)))))))


(defn process [record]
  (with [(utils.Tempdir)]
    (setv filename (-> record.url (.split "/") (get -1)))
    (utils.download_file record.url filename)

    (when (and record.isArchive? (utils.isArchive? filename))
      (xtract.xtract filename :all True)
      (os.remove filename)
      (setv filename (file-select record.basename-glob)))

    (shutil.move filename record.name)
    (utils.make-executable record.name)
    (when record.strip? (os.system f"strip {record.name}"))

    (setv destination (os.path.join Config.location record.name))
    (shutil.move record.name destination)
    (if record.exists?
        (local-db.update-row record.repo record.timestamp)
        (local-db.add-row record.repo record.timestamp))))


(defn set-dry []
  (setv Config.dry-run True))


(defn set-single [repo]
  (local-db.delete-row repo)
  (setv Config.single repo))


(defn main []
  (fetch-remote-local-metadata records)
  (unless Config.dry-run (process-loop records))
  (for [(, repo reason) Config.failures]
    (print f"Failed: https://github.com/{repo} ({reason})"))
  (local-db.finalise))
