(ns chew.main
  (:require [bidi.bidi] [chew.data] [chew.user] [cljs.reader]
            [cljs-time.coerce] [cljs-time.format] [clojure.string]
            [goog.events] [hiccups.runtime])
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

(def routes ["/" {"diag" :diag
  ["split." :split "/step." :step "/ofs." :ofs "/len." :len] :split}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn pick-chgs [step ofs len] (let
  [tmin (:time (first chew.data/changes))
   tfrom (+ tmin (* ofs step)) tto (+ tfrom (* len step))]
  (take-while #(> tto (:time %))
    (drop-while #(> tfrom (:time %)) chew.data/changes))))

(defn split-diagram [split step ofs len] (let
  [margin-left 5 margin-right 5 margin-top 5 margin-bottom 5
   cell-width 70 cell-space 10 bdr-round 8 bdr-col "#DDD" txt-col "#333"
   stack-space 0
   mark-space 10 mark-height 30 mark-ofs-x 35 mark-ofs-y 20
   cells-height 200
   cells-width (- (* len (+ cell-width cell-space)) cell-space)
   total-width (+ margin-left cells-width margin-right)
   total-height (+ margin-top cells-height cell-space cells-height
                   mark-space mark-height margin-bottom)
   stack-up   {:y (- 0 mark-height) :next-y (- 0 mark-height stack-space)}
   stack-down {:y 0                 :next-y (+ mark-height stack-space)}
   categ-amount (fn [categ cofs amount-ftr] (apply + (map #(:amount %) (filter
     #(and ((:tag-filter categ) (:tags %)) (amount-ftr (:amount %)))
     (pick-chgs step cofs 1)))))
   categ-stack (fn self [dir items] (let
     [[[amount categ] & irest] (seq items)]
     (vector :g
       [:rect {:width (str cell-width) :height (str mark-height)
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :fill (:bg-col categ) :x "0" :y (dir :y)}]
       [:text {:text-anchor "middle" :fill (:fg-col categ)
               :x (str mark-ofs-x) :y (str (+ mark-ofs-y (dir :y)))}
        (str amount)]
       (if (empty? irest) [:g]
         [:g {:transform (str "translate(0," (dir :next-y) ")")}
          (self dir irest)]))))]
  (vec (concat [:svg {:width (str total-width) :height (str total-height)}]
    (for [column (range len) :let [
          x (+ margin-left (* column (+ cell-width cell-space)))
          ty (+ margin-top (* 2 cells-height) cell-space mark-space)
          stack-items (fn [amount-ftr] (for
            [categ (:categs (chew.user/splits split))]
            [(categ-amount categ (+ ofs column) amount-ftr) categ]))]]
     (vector :g
       [:g {:transform (str "translate(" x ","
              (+ margin-top cells-height) ")")}
        (categ-stack stack-up (stack-items pos?))]
       [:g {:transform (str "translate(" x ","
              (+ margin-top cells-height cell-space) ")")}
        (categ-stack stack-down (stack-items neg?))]
       [:rect {:width (str cell-width) :height (str mark-height) :fill "none"
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :x (str x) :y (str ty)}]
       [:text {:text-anchor "middle" :fill txt-col
               :x (str (+ x mark-ofs-x)) :y (str (+ ty mark-ofs-y))}
        (str (+ ofs column))]))))))

(js/console.log (str (for [split chew.user/splits]
  [(:title split)
   (for [categ (:categs split)]
    [(:title categ)
     (apply + (map #(:amount %)
       (filter #((:tag-filter categ) (:tags %)) chew.data/changes)))])])))

(def handlers {
  :diag #(for [x chew.data/diag] (list
      [:h3 (:title x) " (" (str (:warns x)) "):"]
      [:pre (clojure.string/join "\n" (:info x))]))
  :split #(let [split (cljs.reader/read-string (:split %))
                step (cljs.reader/read-string (:step %))
                ofs (cljs.reader/read-string (:ofs %))
                len (cljs.reader/read-string (:len %))] (concat
    (if (pos? (warns))
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"]
         " There are " (str (warns)) " validation errors ("
         [:a {:href (href :diag)} "read full report"]
         ")."]] [])
    [[:h1 (:title (get chew.user/splits split))]
     [:nav
       [:ul {:class "pager"}
         (if (pos? ofs)
           [:li {:class "previous"}
             [:a {:href (href :split :split split :step step
                                     :ofs (dec ofs) :len len)}
              "Older"]]
           [:li {:class "previous disabled"} [:a "Older"]])
         [:li {:class "next"}
           [:a {:href (href :split :split split :step step
                                   :ofs (inc ofs) :len len)}
            "Newer"]]]]
     [:div {:class "panel panel-default"}
       [:div {:class "panel-body text-center"}
         (split-diagram split step ofs len)
         [:ul {:class "list-inline"}
          (for [c (:categs (get chew.user/splits split))]
           [:li [:span {:class "label" :style
             (str "color:" (:fg-col c) ";background-color:" (:bg-col c))}
             (:title c)]])]]]
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
