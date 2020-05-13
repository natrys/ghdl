(setv packages [])

(import hy hy.importer)
(import sys os stat re shutil glob platform)

(import [xdg [XDG_CONFIG_HOME]] pathlib)
(setv config-file (/ XDG_CONFIG_HOME (pathlib.Path "ghdl/config")))

(import [ghdl.schema :as schema]
        [ghdl.utils :as utils])


(setv Config (schema.Config))
(defn config [&kwargs conf]
  (when (in "token" conf)
    (setv Config.token (get conf "token"))
    (setv Config.sleep 0))

  (when (in "location" conf)
    (setv Config.location
          (os.path.expanduser (get conf "location"))))
  (utils.make-dir Config.location))


(defn repo [reponame &kwargs info]
  (setv record (schema.Record))
  (setv reponame (-> reponame (.strip "/") (.lower)))
  (setv record.repo reponame)

  (setv record.asset-filter (get info "asset_filter"))

  (if (not (in "bin" info))
      (setv record.name
            (-> record.repo (.split "/") (get 1)))
      (setv record.name (get info "name")))

  (if (in "archive" info)
      (setv record.isArchive? (get info "archive")))

  (if (in "basename_glob" info)
      (setv record.basename-glob (get info "basename_glob"))
      (setv record.basename-glob record.name))

  (if (in "strip" info)
      (setv record.strip? (get info "strip")))
  
  (-> packages (.append record)))


(with [f (open config-file)]
  (hy.eval (hy.importer.hy-parse (.read f))))
