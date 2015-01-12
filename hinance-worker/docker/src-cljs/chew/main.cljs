(ns chew.main
  (:require [bidi.bidi] [chew.data] [clojure.string] [goog.events]
            [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML"
        (hiccups.core/html content)))

(def handlers {
  :home #(html! [:h1 "It's home!"])
  :diag (fn [params] (html! [
    :div {:class "container"} [
      :div {:class "row"} [
        :div {:class "col-md-12"} (concat (map #(list
          [:h1 (:title %) " (" (str (:warns %)) "):"]
          [:pre (clojure.string/join "\n" (:info %))]
        ) chew.data/diag))]]]))})

(def routes ["" {"" :home "/diag" :diag}])

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  ((handlers (match :handler)) (match :route-params))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
