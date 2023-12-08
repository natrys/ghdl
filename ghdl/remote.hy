(import json re dateutil.parser collections [namedtuple])

(require hyrule [-> assoc])


(defclass NoMatchingReleaseException [Exception])


(setv Remote (namedtuple "Record" '("tag" "timestamp" "url_data")))


(defn get-api [record]
  (if (or record.pre-release? record.release-filter)
      f"{record.repo}/releases"
      f"{record.repo}/releases/latest"))


(defn to-unix [timestring]
  (-> timestring (dateutil.parser.parse) (.strftime "%s") (int)))


(defn find-matching-release [resp release-filter]
  (for [release resp]
    (setv name (get release "name"))
    (setv pattern (re.compile release-filter))
    (when (bool (re.search pattern name))
      (return release)))
  (print f"No matching release found for: {release-filter}")
  (raise NoMatchingReleaseException))


(defn/a get-remote [record client [token None]]
  (setv headers {"Accept" "application/vnd.github.v3+json"})
  (setv api (get-api record))
  (when token (assoc headers "Authorization" f"token {token}"))
  (setv resp (.json (await (client.get api :headers headers))))
  (cond
    record.pre-release? (get resp 0)
    record.release-filter (find-matching-release resp record.release-filter)
    True resp))


(defn get-metadata [resp]
  (setv urls
        (lfor asset (get resp "assets")
              #((get asset "name") (get asset "browser_download_url"))))
  (Remote (get resp "tag_name")
          (to-unix (get resp "published_at"))
          urls))


(defn/a metadata [record client [token None]]
  (get-metadata (await (get-remote record client token))))
