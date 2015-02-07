(ns hinance.type)

(defrecord Diag [title warns info])
(defrecord Change [amount time cur label group tags url])
(defrecord Split [title categs])
(defrecord Categ [bg-col fg-col title tag-filter])
(defrecord BankAcc [balance limit paytime cur label])
