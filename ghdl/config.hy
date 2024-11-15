(setv packages [])

(import hy hy.reader)
(import sys os stat re shutil glob platform)

(import xdg [XDG_CONFIG_HOME] pathlib)
(setv config-file (/ XDG_CONFIG_HOME (pathlib.Path "ghdl/config")))

(import ghdl.schema :as schema
        ghdl.utils :as utils)

(require hyrule [->])


(setv Config (schema.Config))
(defn config [#** conf]
  (when (in "token" conf)
    (setv Config.token (get conf "token"))
    (setv Config.sleep 0))

  (when (in "location" conf)
    (setv Config.location
          (os.path.expanduser (get conf "location"))))
  (utils.make-dir Config.location))


(defn repo [reponame #** info]
  (setv record (schema.Record))
  (setv reponame (-> reponame (.strip "/") (str.lower)))
  (setv record.repo reponame)

  (setv record.asset-filter (get info "asset_filter"))

  (if (in "name" info)
      (setv record.name (get info "name"))
      (setv record.name (-> record.repo (.split "/") (get 1))))

  (setv record.release-filter (.get info "release_filter" None))

  (when (in "archive" info)
    (setv record.isArchive? (get info "archive")))

  (when (in "prerelease" info)
    (setv record.pre-release? (get info "prerelease")))

  (if (in "basename_glob" info)
      (setv record.basename-glob (get info "basename_glob"))
      (setv record.basename-glob f"*{record.name}*"))

  (when (in "strip" info)
    (setv record.strip? (get info "strip")))

  (when (in "pin" info)
    (setv record.pin (get info "pin")))
  
  (-> packages (.append record)))


(with [f (open config-file)]
  (hy.eval (hy.reader.read-many (.read f))))
