(ns chew.type)

(defrecord Diag [title warns info])
(defrecord Change [amount time cur label tags url])
(defrecord Categ [title tag-filter fg-col bg-col])
