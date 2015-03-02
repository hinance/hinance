(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr!] :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/" {"diag" :diag "group" :group "split" :split}}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(def handlers! {
  :home (fn [params]
    (doseq [li (sel ".hnav-active")] (set-attr! li :style "display:none"))
    (doseq [li (sel ".hnav") :let [a (sel1 li :a) n (attr li :data-hslice)]]
      (set-attr! a :href (str "split" n ".html#/split." n))))
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
