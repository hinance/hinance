(ns chew.main
  (:require [bidi.bidi] [chew.data] [cljs.reader] [cljs-time.coerce]
    [cljs-time.format] [clojure.string] [goog.events] [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML" content))

(defn warns [] (reduce + (map :warns chew.data/diag)))

(defn page [els] (vector
  :div {:class "container"}
    [:div {:class "row"}
      [:div {:class "col-md-12"} els]]))

(defn amount [ch] (vector
  :span {:style "white-space:nowrap"}
  (.toLocaleString (* 0.01 (:amount ch)) js/undefined
    (clj->js {:style "currency" :currency (:cur ch)}))))

(defn date [unixtime]
  (cljs-time.format/unparse
    (cljs-time.format/formatter "yyyy-MM-dd")
    (cljs-time.coerce/from-long (* 1000 unixtime))))

(defn tag [t] (vector
  :span {:class "label label-default"} (subs (str t) 4)))

(def routes ["/"
  {"diag" :diag ["hist/step." :step "/ofs." :ofs "/len." :len] :hist}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn pick-chgs [step ofs len] (let
  [tmin (:time (first chew.data/changes))
   tfrom (+ tmin (* ofs step)) tto (+ tfrom (* len step))]
  (take-while #(> tto (:time %))
    (drop-while #(> tfrom (:time %)) chew.data/changes))))

(defn diagram [step ofs len] (let
  [margin-top 10 margin-bottom 10 margin-left 10 margin-right 10
   cell-width 70 cell-space 10 bdr-round 8 bdr-col "#DDD" txt-col "#333"
   mark-space 10 mark-height 30 mark-ofs-x 35 mark-ofs-y 20
   cells-height 200
   cells-width (- (* len (+ cell-width cell-space)) cell-space)
   total-width (+ margin-left cells-width margin-right)
   total-height (+ margin-top cells-height cell-space cells-height
                   mark-space mark-height margin-bottom)]
  (vec (concat [:svg {:width (str total-width) :height (str total-height)}]
    [[:rect {:width "100%" :height "100%" :fill "none" :stroke bdr-col
             :rx (str bdr-round) :ry (str bdr-round)}]]
    (for [i (range len) :let [
          x (+ margin-left (* i (+ cell-width cell-space)))
          ty (+ margin-top (* 2 cells-height) cell-space mark-space)]]
     (vector :g
       [:rect {:width (str cell-width) :height (str cells-height) :fill "none"
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :x (str x) :y (str margin-top)}]
       [:rect {:width (str cell-width) :height (str cells-height) :fill "none"
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :x (str x) :y (str (+ margin-top cells-height cell-space))}]
       [:rect {:width (str cell-width) :height (str mark-height) :fill "none"
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :x (str x) :y (str ty)}]
       [:text {:text-anchor "middle" :fill txt-col
               :x (str (+ x mark-ofs-x)) :y (str (+ ty mark-ofs-y))}
        (str (+ ofs i))]))))))

(def handlers {
  :diag #(for [x chew.data/diag] (list
      [:h3 (:title x) " (" (str (:warns x)) "):"]
      [:pre (clojure.string/join "\n" (:info x))]))
  :hist #(let [step (cljs.reader/read-string (:step %))
               ofs (cljs.reader/read-string (:ofs %))
               len (cljs.reader/read-string (:len %))] (concat
    (if (pos? (warns))
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"]
         " There are " (str (warns)) " validation errors ("
         [:a {:href (href :diag)} "read full report"]
         ")."]] [])
    [[:nav
       [:ul {:class "pager"}
         (if (pos? ofs)
           [:li {:class "previous"}
             [:a {:href (href :hist :step step :ofs (dec ofs) :len len)}
              "Older"]]
           [:li {:class "previous disabled"} [:a "Older"]])
         [:li {:class "next"}
           [:a {:href (href :hist :step step :ofs (inc ofs) :len len)}
            "Newer"]]]]
     [:p {:class "text-center"} (diagram step ofs len)]
     [:span {:class "label label-default"} "default"]
     [:span {:class "label label-primary"} "primary"]
     [:span {:class "label label-info"} "info"]
     [:span {:class "label label-success"} "success"]
     [:span {:class "label label-warning"} "warning"]
     [:span {:class "label label-danger"} "danger"]
     [:table {:class "table table-striped"}
       [:thead
         [:tr
           [:th "Date"]
           [:th "Description"]
           [:th "Tags"]
           [:th {:class "text-right"} "Amount"]]]
       [:tbody (for [x (pick-chgs step ofs len)]
         [:tr
           [:td (date (:time x))]
           [:td (if (empty? (:url x)) (:label x)
             [:a {:href (:url x)} (:label x)])]
           [:td
             [:ul {:class "list-inline"}
               (for [t (:tags x)] [:li (tag t)])]]
           [:td {:class "text-right"} (amount x)]])]]
     [:hr]
     [:p {:class "text-muted text-right"}
       "Generated on " chew.data/timestamp]]))})

(def html-content (memoize (fn [path]
  (let [m (bidi.bidi/match-route routes path)]
    (hiccups.core/html (page ((handlers (m :handler)) (m :route-params))))))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(html! (html-content (.-token %))))
  (doto h (.setEnabled true)))
