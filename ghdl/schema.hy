(import os)

(defclass Config []
  (defn __init__ [self]
    (setv self.token None
          self.sleep 1
          self.location (os.path.expanduser "~/.local/bin/"))))


(defclass Record []
  (defn __init__ [self]
    (setv self.toUpdate? True
          self.exists? False
          self.isArchive? False))

  (defn pretty [self]
    (print f"Repo: {self.repo}")
    (print f"Bin: {self.bin}")
    (print f"Exists?: {self.exists?}")
    (print f"Update?: {self.toUpdate?}")
    (print f"Archive?: {self.isArchive?}")
    (print f"URL: {self.url}")
    (print "---------------")))
