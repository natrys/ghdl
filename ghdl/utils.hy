(import os stat requests shutil tempfile)


(defclass Tempdir []
  (defn __enter__ [self]
    (setv self.savedPath (os.getcwd))
    (setv self.tempPath (tempfile.TemporaryDirectory))
    (os.chdir self.tempPath.name))
  (defn __exit__ [self etype value traceback]
    (os.chdir self.savedPath)
    (self.tempPath.cleanup)))


(defn download_file [url filename]
  (print f"Downloading {url}")
  (with [r (requests.get url :stream True :timeout 20)]
    (with [f (open filename "wb")]
      (shutil.copyfileobj r.raw f))))


(defn make-dir [dir]
  (if (not (os.path.exists dir))
      (os.makedirs dir)))


(defn make-file [file]
  (if (not (os.path.exists file))
      (os.mknod file)))


(defn make-executable [filename]
  (setv st (os.stat filename))
  (os.chmod filename (| st.st_mode stat.S_IEXEC)))
