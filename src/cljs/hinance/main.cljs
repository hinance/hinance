(ns hinance.main
  (:require [bidi.bidi] [goog.events] [dommy.core :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/" {"diag" :diag "group" :group "split" :split}}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(def handlers! {
  :home (fn [params] (dorun
    (->> (sel ".hnav-active")
         (map #(dommy.core/set-attr! % :style "display:none")))))
  :diag #(js/console.log "diag")
  :group #(js/console.log "group")
  :split #(js/console.log "split")})

(defn handle! [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    ((handlers! h) ps)))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
