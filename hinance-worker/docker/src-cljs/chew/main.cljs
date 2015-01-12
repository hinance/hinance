(ns chew.main
  (:require [bidi.bidi] [chew.data] [goog.events] [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML"
        (hiccups.core/html content)))

(def handlers {
  :home #(html! [:h1 "It's home!"])
  :diag #(html! [:h1 "It's diag!"])
  :page #(html! [:h1 "It's page " (% :id) "!"])})

(def routes ["/" {"home" :home "diag" :diag ["page/" :id] :page}])

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  ((handlers (match :handler)) (match :route-params))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
