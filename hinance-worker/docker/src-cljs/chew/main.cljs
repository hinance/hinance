(ns chew.main
  (:require [bidi.bidi] [chew.data] [clojure.string]
            [goog.events] [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML"
        (hiccups.core/html content)))

(defn warns [] (reduce + (map :warns chew.data/diag)))

(defn page [els] (vector
  :div {:class "container"}
    [:div {:class "row"}
      [:div {:class "col-md-12"} els]]))

(defn amount [ch] (vector
  :span {:style "white-space:nowrap"}
  (.toLocaleString (* 0.01 (:amount ch)) "en-US"
    (clj->js {:style "currency" :currency (:cur ch)}))))

(def routes ["" {"" :home "/diag" :diag}])

(def handlers {
  :diag #(for [x chew.data/diag] (list
      [:h3 (:title x) " (" (str (:warns x)) "):"]
      [:pre (clojure.string/join "\n" (:info x))]))
  :home #(concat
    (if (== 0 (warns)) []
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"]
         " There are " (str (warns)) " validation errors ("
         [:a {:href (str "#" (bidi.bidi/path-for routes :diag))}
           "read full report"]
         ")."]])
    [[:table {:class "table table-striped"}
       [:thead
         [:tr
           [:th "Date"]
           [:th "Description"]
           [:th "Tags"]
           [:th {:class "text-right"} "Amount"]]]
       [:tbody (for [x chew.data/changes]
         [:tr
           [:td (str (:time x))]
           [:td (if (empty? (:url x)) (:label x)
             [:a {:href (:url x)} (:label x)])]
           [:td (str (:tags x))]
           [:td {:class "text-right"} (amount x)]])]]
     [:hr]
     [:p {:class "text-muted text-right"}
       "Generated on " chew.data/timestamp]])})

(defn handle! [path] (let [match (bidi.bidi/match-route routes path)]
  (html! (page ((handlers (match :handler)) (match :route-params))))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
