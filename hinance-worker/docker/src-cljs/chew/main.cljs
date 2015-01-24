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
  ["split." :split "/step." :step "/ofs." :ofs "/len." :len
   "/sel-ofs." :sel-ofs "/sel-cat." :sel-cat] :split}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn pick-chgs [step ofs len] (js/console.log "pick-chgs") (let
  [tmin (:time (first chew.data/changes))
   tfrom (+ tmin (* ofs step)) tto (+ tfrom (* len step))]
  (take-while #(> tto (:time %))
    (drop-while #(> tfrom (:time %)) chew.data/changes))))

(def categ-amounts (memoize (fn [step categ cofs]
  (js/console.log "categ-amounts")
  (map :amount (filter #((:tag-filter categ) (:tags %))
                       (pick-chgs step cofs 1))))))

(def categ-amount (memoize (fn [step categ cofs amount-ftr]
  (js/console.log "categ-amount")
  (apply + (filter amount-ftr (categ-amounts step categ cofs))))))

(def chgs-table (memoize (fn [split step sel-ofs sel-cat]
  (js/console.log "chgs-table")
  (hiccups.core/html
  [:table {:class "table table-striped"}
    [:thead [:tr [:th "Date"] [:th "Description"] [:th "Tags"]
                 [:th {:class "text-right"} "Amount"]]]
    [:tbody (for [x (pick-chgs step sel-ofs 1)
      :when ((:tag-filter ((:categs (chew.user/splits split)) sel-cat))
             (:tags x))]
      [:tr [:td (date (:time x))]
           [:td (if (empty? (:url x)) (:label x)
             [:a {:href (:url x)} (:label x)])]
           [:td [:ul {:class "list-inline"}
                  (for [t (:tags x)] [:li (tag t)])]]
           [:td {:class "text-right"} (amount x)]])]]))))

(defn split-diagram [split step ofs len sel-ofs sel-cat] (js/console.log "split-diagram") (let
  [margin-left 5 margin-right 5 margin-top 5 margin-bottom 5
   cell-width 70 cell-space 10 bdr-round 8 bdr-col "#DDD" txt-col "#333"
   amount-scale 0.001 sel-col "#000" sel-width 5
   mark-space 10 mark-height 30 mark-ofs-x 35 mark-ofs-y 20
   stack-up   (fn [h] (hash-map :y (- 0 h) :next-y (- h)))
   stack-down (fn [h] (hash-map :y 0       :next-y h))
   svg-stack (fn self [dir cofs items]
     (js/console.log "svg-stack")
     (if (empty? items) [:g] (let
     [[[amount height icat categ] & irest] (seq items)]
     (vector :g
       [:a {:xlink:href (href :split :split split :step step :ofs ofs
                          :len len :sel-ofs cofs :sel-cat icat)}
         [:rect (merge (if (and (= sel-ofs cofs) (= sel-cat icat))
           {:stroke sel-col :stroke-width (str sel-width)}
           {:stroke bdr-col})
           {:width (str cell-width) :height (str height) :fill (:bg-col categ)
            :rx (str bdr-round) :ry (str bdr-round)
            :x "0" :y ((dir height) :y)})]
         [:text {:text-anchor "middle" :fill (:fg-col categ)
                 :x (str mark-ofs-x) :y (str (+ mark-ofs-y ((dir height) :y)))}
           (str amount)]]
       (if (empty? irest) [:g]
         [:g {:transform (str "translate(0," ((dir height) :next-y) ")")}
          (self dir cofs irest)])))))
   stack-items (fn [column amount-ftr] (sort-by (comp Math/abs first) < (for
     [[icat categ] (map-indexed vector (:categs (chew.user/splits split))) :let
      [amount (categ-amount step categ (+ ofs column) amount-ftr)
       height (max mark-height (* amount-scale (Math/abs amount)))]
      :when (not (zero? amount))]
     [(int (/ amount 100)) height icat categ])))
   max-stack-height (fn [amount-ftr] (apply max (for [column (range len)]
     (apply + (map second (stack-items column amount-ftr))))))
   cells-height-pos (max-stack-height pos?)
   cells-height-neg (max-stack-height neg?)
   cells-width (- (* len (+ cell-width cell-space)) cell-space)
   total-width (+ margin-left cells-width margin-right)
   total-height (+ margin-top cells-height-pos mark-space mark-height
                   mark-space cells-height-neg margin-bottom)]
  (vec (concat [:svg {:width (str total-width) :height (str total-height)}]
    (for [column (range len) :let [
          x (+ margin-left (* column (+ cell-width cell-space)))
          mark-y (+ margin-top cells-height-pos mark-space)
          cofs (+ ofs column)]]
     (vector :g
       [:g {:transform (str "translate(" x ","
              (+ margin-top cells-height-pos) ")")}
        (svg-stack stack-up cofs (stack-items column pos?))]
       [:rect {:width (str cell-width) :height (str mark-height) :fill "none"
               :rx (str bdr-round) :ry (str bdr-round) :stroke bdr-col
               :x (str x) :y (str mark-y)}]
       [:text {:text-anchor "middle" :fill txt-col
               :x (str (+ x mark-ofs-x)) :y (str (+ mark-y mark-ofs-y))}
        (str cofs)]
       [:g {:transform (str "translate(" x ","
              (+ mark-y mark-height mark-space) ")")}
        (svg-stack stack-down cofs (stack-items column neg?))]))))))

(def handlers {
  :diag #(for [x chew.data/diag] (list
      [:h3 (:title x) " (" (str (:warns x)) "):"]
      [:pre (clojure.string/join "\n" (:info x))]))
  :split (fn [params] (js/console.log "handlers:split")
          (let [split (cljs.reader/read-string (:split params))
                step (cljs.reader/read-string (:step params))
                ofs (cljs.reader/read-string (:ofs params))
                len (cljs.reader/read-string (:len params))
                sel-ofs (cljs.reader/read-string (:sel-ofs params))
                sel-cat (cljs.reader/read-string (:sel-cat params))] (concat
    (if (pos? (warns))
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"]
         " There are " (str (warns)) " validation errors ("
         [:a {:href (href :diag)} "read full report"]
         ")."]] [])
    [[:h1 (:title (chew.user/splits split))]
     [:nav
       [:ul {:class "pager"}
         (if (pos? ofs)
           [:li {:class "previous"}
             [:a {:href (href :split :split split :step step :ofs (dec ofs)
                         :len len :sel-ofs sel-ofs :sel-cat sel-cat)}
              "Older"]]
           [:li {:class "previous disabled"} [:a "Older"]])
         [:li {:class "next"}
           [:a {:href (href :split :split split :step step :ofs (inc ofs)
                       :len len :sel-ofs sel-ofs :sel-cat sel-cat)}
            "Newer"]]]]
     [:div {:class "panel panel-default"}
       [:div {:class "panel-body text-center"}
         (split-diagram split step ofs len sel-ofs sel-cat)
         [:ul {:class "list-inline"}
          (for [c (:categs (chew.user/splits split))]
           [:li [:span {:class "label" :style
             (str "color:" (:fg-col c) ";background-color:" (:bg-col c))}
             (:title c)]])]]]
     (chgs-table split step sel-ofs sel-cat)
     [:hr]
     [:p {:class "text-muted text-right"}
       "Generated on " chew.data/timestamp]])))})

(def html-content (memoize (fn [path]
  (let [m (bidi.bidi/match-route routes path)]
    (hiccups.core/html (page ((handlers (m :handler)) (m :route-params))))))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(html! (html-content (.-token %))))
  (doto h (.setEnabled true)))
