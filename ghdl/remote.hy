(import requests json dateutil.parser [collections [namedtuple]])


(setv Remote (namedtuple "Record" "tag timestamp url_data"))


(defn get-api [repo]
  (return f"https://api.github.com/repos/{repo}/releases/latest"))


(defn to-unix [timestring]
  (-> timestring (dateutil.parser.parse) (.strftime "%s") (int)))


(defn get-remote [repo &optional token]
  (setv headers {"Accept" "application/vnd.github.v3+json"} api (get-api repo))
  (if token (assoc headers "Authorization" f"token {token}"))
  (return (.json (requests.get api :headers headers))))


(defn get-metadata [resp]
  (setv urls
        (lfor asset (get resp "assets")
              (, (get asset "name")
                 (get asset "browser_download_url"))))
  (Remote (get resp "tag_name")
          (to-unix (get resp "published_at"))
          urls))


(defn metadata [repo &optional token]
  (try
    (get-metadata (get-remote repo token))
    (except [] None)))
