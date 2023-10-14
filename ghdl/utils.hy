(import os stat httpx shutil tempfile magic)


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
  (with [r (httpx.stream "GET" url :timeout 20 :follow_redirects True)]
    (with [f (open filename "wb")]
      (for [chunk (r.iter_raw)]
        (f.write chunk)))))


(defn make-dir [dir]
  (when (not (os.path.exists dir))
    (os.makedirs dir)))


(defn make-file [file]
  (when (not (os.path.exists file))
    (os.mknod file)))


(defn make-executable [filename]
  (setv st (os.stat filename))
  (os.chmod filename (| st.st_mode stat.S_IEXEC)))


(setv archive-mime-types #{
  "application/zip"
  "application/gzip"
  "application/x-xz"
  "application/x-tar"
  "application/x-gzip"
  "application/x-bzip2"
  "application/x-lzop"
  "application/x-lzip"
  "application/x-lz4"
  "application/x-compress"
  "application/x-rar-compressed"
  "application/x-7z-compressed"
  "application/x-unix-archive"
  "application/x-rpm"
  "application/vnd.debian.binary-package"
})

(setv executable-mime-types #{
  "application/elf"
  "application/x-sharedlib"
  "application/x-pie-executable"
  "application/x-executable"
})


(defn isExecutable? [filename]
  (in (magic.from-file filename :mime True) executable-mime-types))


(defn isArchive? [filename]
  (in (magic.from-file filename :mime True) archive-mime-types))
