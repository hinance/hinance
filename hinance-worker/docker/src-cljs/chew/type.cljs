(ns chew.type)

(defrecord Diag [title warns info])
(defrecord Change [amount time cur label tags url])
(defrecord Split [title categs])
(defrecord Categ [bg-col fg-col title tag-filter])
