(import sqlite3 pathlib)
(import ghdl.utils :as utils)
(import xdg [XDG_DATA_HOME])


(defclass Record []
  (defn __init__ [self repo timestamp]
    (setv self.repo repo)
    (setv self.timestamp timestamp)))


(defclass LocalRecord []
  (defn __init__ [self]
    (setv data-dir (/ XDG_DATA_HOME (pathlib.Path "ghdl")))
    (setv self.data-db (/ data-dir (pathlib.Path "db")))
    (utils.make-dir data-dir)
    (setv self.connection (sqlite3.connect self.data-db))
    (setv command "
    CREATE TABLE IF NOT EXISTS records (
        repo text NOT NULL UNIQUE,
        timestamp integer NOT NULL
    );

    CREATE UNIQUE INDEX IF NOT EXISTS record_index ON records (repo) ;")
    (with [con self.connection]
      (con.executescript command))
    
    (return None))

  (defn fetch-row [self repo]
    (setv command "SELECT * FROM records WHERE repo = ? ;")
    (setv cursor (self.connection.cursor))
    (cursor.execute command #(repo))
    (setv result (cursor.fetchone))
    (cursor.close)
    (when result
      (setv result (Record (unpack-iterable result))))
    (return result))

  (defn add-row [self repo timestamp]
    (setv command "INSERT INTO records(repo, timestamp) VALUES(?, ?) ;")
    (with [con self.connection]
      (con.execute command #(repo timestamp))))

  (defn update-row [self repo timestamp]
    (setv command "UPDATE records SET timestamp = ? WHERE repo = ? ;")
    (with [con self.connection]
      (con.execute command #(timestamp repo))))

  (defn delete-row [self repo]
    (setv command "DELETE FROM records WHERE repo = ? ;")
    (with [con self.connection]
      (con.execute command #(repo))))

  (defn finalise [self]
    (self.connection.close)))
