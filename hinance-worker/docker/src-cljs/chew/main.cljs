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
  :home #(concat
    (if (== 0 (warns)) []
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"]
         " There are " (str (warns)) " validation errors ("
         [:a {:href (str "#" (bidi.bidi/path-for routes :diag))}
           "read full report"]
         ")."]])
    [[:h1 "Changes:"]])
  :diag (fn [params] (concat (map #(list
      [:h1 (:title %) " (" (str (:warns %)) "):"]
      [:pre (clojure.string/join "\n" (:info %))]
    ) chew.data/diag)))})

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  (html! (page ((handlers (match :handler)) (match :route-params))))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
