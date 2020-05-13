(import filetype xtract)

(import os fnmatch re shutil traceback sys time)
(import [ghdl.config :as config]
        [ghdl.remote :as remote]
        [ghdl.local :as local]
        [ghdl.utils :as utils])

(setv records config.packages)
(setv local-db (local.LocalRecord))


(defn file-select [glob]
  (for [[root dir files] (os.walk ".")]
    (for [file files]
      (setv fullpath (os.path.join root file))
      (when (fnmatch.fnmatch file glob)
        (return fullpath)))))


(defn url-select [url-filter url_data]
  (defn run-filter [f]
    (for [[name url] url_data]
      (if (f name)
          (return url))))
  
  (if (isinstance url-filter str)
      (do
        (setv pattern (re.compile url-filter re.IGNORECASE))
        (run-filter (fn [name] (bool (re.search pattern name)))))
      (run-filter url-filter)))


(defn add-remote-metadata [record]
  (setv remote-metadata (remote.metadata record.repo config.Config.token))

  ;; Network error
  (if (not remote-metadata) (do (setv record.toUpdate? False) (return)))

  (setv dl-url (url-select record.url-filter remote-metadata.url_data))
  (if dl-url
      (setv record.url dl-url)
      ;; User filter couldn't find any candidate
      (do (setv record.toUpdate? False) (return)))

  (setv record.tag remote-metadata.tag)
  (setv record.timestamp remote-metadata.timestamp))


(defn add-local-metadata [record]
  (setv local (local-db.fetch-row record.repo))
  (when local
    (setv record.exists? True)
    (if (<= record.timestamp local.timestamp)
        (setv record.toUpdate? False))))


(defn fetch-remote-local-metadata [records]
  (for [record records]
    (add-remote-metadata record)
    ;; rate limiting can't hurt
    (time.sleep config.Config.sleep)
    (add-local-metadata record)
    (record.pretty)))


(defn process-loop [records]
  (for [record records]
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

    (when (and record.isArchive? (filetype.archive-match filename))
      (xtract.xtract filename :all True)
      (os.remove filename)
      (setv filename (file-select record.basename-glob)))

    (shutil.move filename record.name)
    (utils.make-executable record.name)
    (when record.strip? (os.system f"strip {record.name}"))

    (setv destination (os.path.join config.Config.location record.name))
    (shutil.move record.name destination)
    (if record.exists?
        (local-db.update-row record.repo record.timestamp)
        (local-db.add-row record.repo record.timestamp))))


(defn delete-local [repo]
  (local-db.delete-row repo)
  (local-db.finalise))


(defn set-dry []
  (setv config.Config.dry-run True))


(defn main []
  (fetch-remote-local-metadata records)
  (unless config.Config.dry-run (process-loop records))
  (local-db.finalise))
