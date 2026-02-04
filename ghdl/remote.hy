(import json re dateutil.parser collections [namedtuple])

(import hyrule [assoc])
(require hyrule [->])


(defclass NoMatchingReleaseException [Exception])


(setv Remote (namedtuple "Record" '("tag" "timestamp" "url_data")))


(defn get-api [record]
  (if (or record.pre-release? record.release-filter)
      f"{record.repo}/releases"
      f"{record.repo}/releases/latest"))


(defn to-unix [timestring]
  (-> timestring (dateutil.parser.parse) (.strftime "%s") (int)))


(defn find-matching-release [resp record]
  (setv pattern (re.compile record.release-filter))
  (for [release resp]
    (when (and (bool (re.search pattern (get release "name")))
               (= (get release "prerelease") record.pre-release?))
      (return release)))
  (print f"No matching release found for: {record.release-filter}")
  (raise NoMatchingReleaseException))


(defn :async get-remote [record client [token None]]
  (setv headers {"Accept" "application/vnd.github.v3+json"})
  (setv api (get-api record))
  (when token (assoc headers "Authorization" f"token {token}"))
  (setv response (await (client.get api :headers headers)))
  (when (!= response.status_code 200)
    (raise (Exception f"Github API error {response.status_code} for {record.repo}")))
  (setv resp
        (try
          (.json response)
          (except [e Exception]
            (raise (Exception f"Invalid JSON from Github API for {record.repo}")))))

  (cond
    record.pre-release? (get resp 0)
    record.release-filter (find-matching-release resp record)
    True resp))


(defn get-metadata [resp]
  (setv urls
        (lfor asset (get resp "assets")
              #((get asset "name") (get asset "browser_download_url"))))
  (Remote (get resp "tag_name")
          (to-unix (get resp "published_at"))
          urls))


(defn :async metadata [record client [token None]]
  (get-metadata (await (get-remote record client token))))
