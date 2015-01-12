(ns chew.main
  (:require [bidi.bidi] [chew.data] [clojure.string] [goog.events]
            [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML"
        (hiccups.core/html content)))

(defn warns [] (reduce + (map :warns chew.data/diag)))

(defn page [els] (vector
  :div {:class "container"} [
    :div {:class "row"} [
      :div {:class "col-md-12"} els]]))

(def routes ["" {"" :home "/diag" :diag}])

(def handlers {
  :home #(html! (page (concat
    (if (== 0 (warns)) []
      [[:a {:href (str "#" (bidi.bidi/path-for routes :diag))}
        "There are " (str (warns)) " warnings"]])
    [[:h1 "Changes:"]])))
  :diag (fn [params] (html! (page (concat (map #(list
      [:h1 (:title %) " (" (str (:warns %)) "):"]
      [:pre (clojure.string/join "\n" (:info %))]
    ) chew.data/diag)))))})

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  ((handlers (match :handler)) (match :route-params))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))