(import os)

(defclass Config []
  (defn __init__ [self]
    (setv self.token None
          self.sleep 1
          self.dry-run False
          self.single None
          self.location (os.path.expanduser "~/.local/bin/"))))


(defclass Record []
  (defn __init__ [self]
    (setv self.toUpdate? True
          self.exists? False
          self.strip? True
          self.isArchive? True))

  (defn pretty [self]
    (print f"Repo: {self.repo}")
    (print f"Name: {self.name}")
    (print f"Exists?: {self.exists?}")
    (print f"Update?: {self.toUpdate?}")
    ;(print f"Archive?: {self.isArchive?}")
    (print f"URL: {self.url}")
    (print "---------------")))
