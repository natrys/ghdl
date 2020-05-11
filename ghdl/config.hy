(setv packages [])

(import hy hy.importer)
(import sys os stat re shutil glob platform)

(import [xdg [XDG_CONFIG_HOME]] pathlib)
(setv config-file (/ XDG_CONFIG_HOME (pathlib.Path "ghdl/config")))

(import [ghdl.schema :as schema]
        [ghdl.utils :as utils])


(setv Config (schema.Config))
(defn config [&kwargs conf]
  (if (in "token" conf)
      (setv Config.token (get conf "token"))
      (setv Config.token.sleep 0))

  (if (in "location" conf)
      (setv Config.location
            (os.path.expanduser (get conf "location"))))
  (utils.make-dir Config.location))


(defn repo [reponame &kwargs info]
  (setv record (schema.Record))
  (setv reponame (-> reponame (.strip "/") (.lower)))
  (setv record.repo reponame)
  
  (if (not (in "bin" info))
      (setv record.bin
            (-> record.repo (.split "/") (get 1)))
      (setv record.bin (get info "bin")))

  (setv record.url-filter (get info "url_filter"))

  (if (in "archive" info)
      (setv record.isArchive? (get info "archive")))

  (if record.isArchive?
      (if (in "bin_glob" info)
          (setv record.bin-glob (get info "bin_glob"))
          (do (print f"Provide 'bin-glob' for {record.repo}") (sys.exit))))
  
  (-> packages (.append record)))


(with [f (open config-file)]
  (hy.eval (hy.importer.hy-parse (.read f))))
