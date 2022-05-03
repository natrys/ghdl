(import requests json dateutil.parser collections [namedtuple])

(require hyrule [-> assoc])


(setv Remote (namedtuple "Record" '("tag" "timestamp" "url_data")))


(defn get-api [repo pre-release?]
  (if pre-release?
      f"https://api.github.com/repos/{repo}/releases"
      f"https://api.github.com/repos/{repo}/releases/latest"))


(defn to-unix [timestring]
  (-> timestring (dateutil.parser.parse) (.strftime "%s") (int)))


(defn get-remote [repo pre-release? [token None]]
  (setv headers {"Accept" "application/vnd.github.v3+json"})
  (setv api (get-api repo pre-release?))
  (when token (assoc headers "Authorization" f"token {token}"))
  (setv resp (.json (requests.get api :headers headers)))
  (return (if pre-release? (get resp 0) resp)))


(defn get-metadata [resp]
  (setv urls
        (lfor asset (get resp "assets")
              (, (get asset "name")
                 (get asset "browser_download_url"))))
  (Remote (get resp "tag_name")
          (to-unix (get resp "published_at"))
          urls))


(defn metadata [repo pre-release? [token None]]
  (try
    (get-metadata (get-remote repo pre-release? token))
    (except []
      (print f"Error fetching metadata from Github API for {repo}")
      None)))
