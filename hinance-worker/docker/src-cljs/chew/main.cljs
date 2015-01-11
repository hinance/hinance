(ns chew.main
  (:require [bidi.bidi :as bidi] [goog.events :as events] [chew.data :as data])
  (:import goog.History goog.history.EventType))

(defn set-html! [content]
  (aset (js/document.getElementById "content") "innerHTML" content))

(def handlers {
  :home #(set-html! "<h1>It's home!</h1>")
  :diag #(set-html! "<h1>It's diag!</h1>")
  :page #(set-html! (str "<h1>It's page " (% :id) "!</h1>"))})

(def routes ["/" {"home" :home "diag" :diag ["page/" :id] :page}])

(defn handle! [path] (let [match (bidi/match-route routes path)]
  ((handlers (match :handler)) (match :route-params))))

(let [h (History.)]
  (events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
