(ns chew.main
  (:require [bidi.bidi] [chew.data] [chew.user] [cljs.reader]
            [cljs-time.coerce] [cljs-time.format] [clojure.string]
            [goog.events] [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(def cfg {
  :margin-left 5 :margin-right 5 :margin-top 5 :margin-bottom 5
  :sel-col "#000" :sel-width 5 :bdr-round 8 :bdr-col "#DDD"
  :cell-width 70 :cell-space 10 :txt-col "#333" :amount-scale 0.001
  :mark-space 10 :mark-height 30 :mark-ofs-x 35 :mark-ofs-y 20})

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

(defn svg-stack [split step ofs len sel-ofs sel-cat dir cofs items]
  (js/console.log "svg-stack")
  (if (empty? items) [:g] (let
  [[[amount height icat categ] & irest] (seq items)]
  (vector :g
    [:a {:xlink:href (href :split :split split :step step :ofs ofs
                       :len len :sel-ofs cofs :sel-cat icat)}
      [:rect (merge (if (and (= sel-ofs cofs) (= sel-cat icat))
        {:stroke (cfg :sel-col) :stroke-width (str (cfg :sel-width))}
        {:stroke (cfg :bdr-col)})
        {:width (str (cfg :cell-width)) :height (str height)
         :fill (:bg-col categ) :rx (str (cfg :bdr-round))
         :ry (str (cfg :bdr-round)) :x "0" :y ((dir height) :y)})]
      [:text {:text-anchor "middle" :fill (:fg-col categ)
              :x (str (cfg :mark-ofs-x))
              :y (str (+ (cfg :mark-ofs-y) ((dir height) :y)))}
        (str amount)]]
    (if (empty? irest) [:g]
      [:g {:transform (str "translate(0," ((dir height) :next-y) ")")}
       (svg-stack split step ofs len sel-ofs sel-cat dir cofs irest)])))))

(defn stack-up   [h] (hash-map :y (- 0 h) :next-y (- h)))
(defn stack-down [h] (hash-map :y 0       :next-y h))

(defn stack-items [split step cofs amount-ftr]
  (sort-by (comp Math/abs first) < (for
    [[icat categ] (map-indexed vector (:categs (chew.user/splits split))) :let
     [amount (categ-amount step categ cofs amount-ftr)
      height (max (cfg :mark-height) (* (cfg :amount-scale)(Math/abs amount)))]
     :when (not (zero? amount))]
    [(int (/ amount 100)) height icat categ])))

(defn split-diagram [split step ofs len sel-ofs sel-cat] (js/console.log "split-diagram") (let
  [max-stack-height (fn [amount-ftr] (apply max (for [column (range len)]
     (apply + (map second (stack-items split step(+ ofs column)amount-ftr))))))
   cells-height-pos (max-stack-height pos?)
   cells-height-neg (max-stack-height neg?)
   cell-wspace (+ (cfg :cell-width) (cfg :cell-space))
   cells-width (- (* len cell-wspace) (cfg :cell-space))
   total-width (+ (cfg :margin-left) cells-width (cfg :margin-right))
   total-height (+ (cfg :margin-top) cells-height-pos
                   (cfg :mark-space) (cfg :mark-height)
                   (cfg :mark-space) cells-height-neg (cfg :margin-bottom))]
  (vec (concat [:svg {:width (str total-width) :height (str total-height)}]
    (for [column (range len) :let [
          x (+ (cfg :margin-left) (* column cell-wspace))
          mark-y (+ (cfg :margin-top) cells-height-pos (cfg :mark-space))
          cofs (+ ofs column)]]
     (vector :g
       [:g {:transform (str "translate(" x ","
              (+ (cfg :margin-top) cells-height-pos) ")")}
        (svg-stack split step ofs len sel-ofs sel-cat stack-up cofs
          (stack-items split step cofs pos?))]
       [:rect {:width (str (cfg :cell-width)) :height (str (cfg :mark-height))
               :fill "none" :stroke (cfg :bdr-col) :rx (str (cfg :bdr-round))
               :ry (str (cfg :bdr-round)) :x (str x) :y (str mark-y)}]
       [:text {:text-anchor "middle" :fill (cfg :txt-col)
               :x (str (+ x (cfg :mark-ofs-x)))
               :y (str (+ mark-y (cfg :mark-ofs-y)))}
        (str cofs)]
       [:g {:transform (str "translate(" x ","
              (+ mark-y (cfg :mark-height) (cfg :mark-space)) ")")}
        (svg-stack split step ofs len sel-ofs sel-cat stack-down cofs
          (stack-items split step cofs neg?))]))))))

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
