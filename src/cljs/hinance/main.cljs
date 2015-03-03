(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr!] :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/" {"diag" :diag "group" :group "slice" :slice}}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn hide! [x] (set-attr! x :style "display:none"))
(defn show! [x] (set-attr! x :style "display:inherit"))
(defn set-hnav-href! [li] (let [a (sel1 li :a) n (attr li :data-hslice)]
  (set-attr! a :href (str "slice" n ".html" (href :slice)))
  (identity li)))

(defn handle-home! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map set-hnav-href!) (map show!)))))

(defn handle-slice! [params] (let
  [cur-slice (attr (sel1 :#hparams) :data-hslice)
   cur? #(= (attr % :data-hslice) cur-slice)] (dorun (concat
  (->> (sel :.hnav-active) (map #((if (cur? %) show! hide!) %)))
  (->> (sel :.hnav) (map #((if(cur? %)hide! show!)%))(map set-hnav-href!))))))

(def handlers! {
  :home handle-home!
  :diag #(js/console.log "diag")
  :group #(js/console.log "group")
  :slice handle-slice!})

(defn handle! [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    ((handlers! h) ps)))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
