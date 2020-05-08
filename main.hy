(import xtract)

(import os glob re shutil config remote local localagain utils)

(setv records config.packages)
(setv local-metadata (localagain.LocalRecord))

(defn url-select [url-filter url_data]
  (defn run-filter [f]
    (for [[name url] url_data]
      (if (f name)
          (return url))))
  
  (if (isinstance url-filter str)
      (do
        (setv pattern (re.compile url-filter))
        (run-filter (fn [name] (bool (re.search pattern name)))))
      (run-filter url-filter)))

(defn add-remote-metadata [records]
  (for [record records]
    (setv remote-metadata (remote.metadata record.repo config.Config.token))

    ;; Network error
    (if (not remote-metadata) (do (setv record.toUpdate? False) (continue)))

    (setv dl-url (url-select record.url-filter remote-metadata.url_data))
    (if dl-url
        (setv record.url dl-url)
        ;; User filter couldn't find any candidate
        (do (setv record.toUpdate? False) (continue)))

    (setv record.tag remote-metadata.tag)
    (setv record.timestamp remote-metadata.timestamp)))

(defn add-local-metadata [records]
  (for [record records]
    (setv local (local-metadata.fetch-row record.repo))
    (when local
      (setv record.exists? True)
      (print f"{local.repo} {local.timestamp} || {record.repo} {record.timestamp}")
      (if (<= record.timestamp local.timestamp)
          (setv record.toUpdate? False)))))

(defn show-records [records]
  (for [record records]
    (record.pretty)))

(defn process-loop [records]
  (for [record records]
    (when record.toUpdate?
      (process-record record)
      (try
        (except [] (print f"Failed to process: {record.repo}"))
        ))))

(defn process-record [record]
  (with [(utils.Tempdir)]
    (setv filename
          (if record.isArchive?
              (-> record.url (.split "/") (get -1))
              record.bin))
    (utils.download_file record.url filename)
    (when record.isArchive?
      (xtract.xtract filename :all True)
      (setv filename (get (glob.glob record.archive_glob) 0)))
    
    (shutil.move filename record.bin)
    (utils.make-executable record.bin)
    (setv destination (os.path.join config.Config.location record.bin))
    (shutil.move record.bin destination)
    (if record.exists?
        (local-metadata.update-row record.repo record.timestamp)
        (local-metadata.add-row record.repo record.timestamp))))

(defn main []
  (add-remote-metadata records)
  (add-local-metadata records)
  (show-records records)
  (process-loop records))

(main)
