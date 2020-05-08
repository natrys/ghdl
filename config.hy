(import hy hy.importer)
(import os stat re shutil glob platform)

(import [xdg [XDG_CONFIG_HOME]] pathlib)
(setv config-file (/ XDG_CONFIG_HOME (pathlib.Path "ghdl/config")))

(import schema utils)

(setv Config (schema.Config))
(defn config [&kwargs conf]
  (if (in "token" conf)
      (setv Config.token (get conf "token")))
  (setv Config.location
        (os.path.expanduser
          (if (in "location" conf) (get conf "location") "~/.local/bin/")))
  (utils.make-dir Config.location))


(setv packages [])

(defn repo [name &kwargs info]
  (setv record (schema.Record))
  (setv name (.strip name "/"))
  (setv record.repo name)
  
  (if (not (in "bin" info))
      (setv record.bin
            (-> name (.split "/") (get 1)))
      (setv record.bin (get info "bin")))

  (setv record.url-filter (get info "url_filter"))

  (if (in "archive" info)
      (setv record.isArchive? (get info "archive")
            record.archive-glob (get info "archive_glob")))
  
  (-> packages (.append record)))



(with [f (open config-file)]
  (hy.eval (hy.importer.hy-parse (.read f))))

(if (= __name__ "__main__")
    (do
      (setv taskell (get packages 1))

      (setv testcase
            ["taskell-1.9.3_x86-64-linux.deb" "taskell-1.9.3_x86-64-linux.tar.gz"
             "taskell-static-1.9.3_x86-64-mac.tar.gz"])

      (for [url testcase]
        (if (taskell.url-filter url)
            (print url)))
      ))
