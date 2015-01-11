(ns chew.main (:require [bidi.bidi] [chew.data] [goog.events] [sablono.core]))

(defn set-html! [content]
  (aset (js/document.getElementById "content") "innerHTML" content))

(def handlers {
  :home #(set-html! "<h1>It's home!</h1>")
  :diag #(set-html! "<h1>It's diag!</h1>")
  :page #(set-html! (str "<h1>It's page " (% :id) "!</h1>"))})

(def routes ["/" {"home" :home "diag" :diag ["page/" :id] :page}])

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  ((handlers (match :handler)) (match :route-params))))

(let [h (goog.History.)]
  (goog.events/listen h goog.history.EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
