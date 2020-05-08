(import [enum [Enum]])

(defclass Config []
  (defn __init__ [self]
    (setv self.token None
          self.location "~/.local/bin/"))

  (defn pretty [self]
    (print f"token: {self.token}")
    (print f"location: {self.location}")
    (print "---------------")))

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
    (print f"url: {self.url}")
    (print "---------------")))


(if (= __name__ "__main__")
    (do
      (setv rec (Record))
      (print rec.toUpdate)))
