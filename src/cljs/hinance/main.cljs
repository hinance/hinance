(ns hinance.main
  (:require [bidi.bidi] [hinance.data] [hinance.user] [cljs.reader]
            [cljs-time.coerce] [cljs-time.format] [clojure.string]
            [goog.events] [hiccups.runtime])
  (:require-macros [hiccups.core])
  (:import goog.History goog.history.EventType))

(def cfg {:len-default {:sm 16 :xs 5} :lim-default {:sm 50 :xs 10}
  :margin-left 5 :margin-right 5 :margin-top 5 :margin-bottom 5
  :sel-col "#000" :sel-width 5 :bdr-round 8 :bdr-col "#DDD"
  :cell-width 70 :cell-space 10 :txt-col "#333" :amount-scale 400
  :mark-space 10 :mark-height 30 :mark-ofs-x 35 :mark-ofs-y 20})

(def step-month (/ (* 365 24 3600) 12))

(def routes ["" {"" :home "/" {"diag" :diag ["group." :group] :group
  ["split." :split "/step." :step "/ofs." :ofs "/len." :len "/srt." :srt
   "/asc." :asc "/lim." :lim "/sel-ofs." :sel-ofs "/sel-cat." :sel-cat
  ] :split}}])

(def lookup {:chgsact hinance.data/chgsact
             :chgsplan hinance.data/chgsplan
             :chgsdiff hinance.data/chgsdiff})

(defn html! [content]
  (aset (js/document.getElementById "content") "innerHTML" content))

(defn warns [] (reduce + (map :warns hinance.data/diag)))

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn chgs-time-span [] (- (:time (last hinance.data/chgsact))
                           (:time (first hinance.data/chgsact))))

(defn step-actual [len] (Math/ceil (/ (+ 1 (chgs-time-span)) len)))

(defn first-time [] (:time (first hinance.data/chgsact)))

(defn split-href [screen params-old params-new] (let
  [params (merge (or params-old {}) params-new)
   param-read (fn [k v] (cljs.reader/read-string (str (or (params k) v))))
   len (or (params :len) ((cfg :len-default) screen))
   step (param-read :step (step-actual len))
   sel-ofs (param-read :sel-ofs (Math/floor (/ (chgs-time-span) step)))
   ofs (param-read :ofs (max 0 (+ 1 (- sel-ofs len)))) asc (param-read :asc 0)
   srt (or (params :srt) "time") split (params :split)
   lim (or (params :lim) ((cfg :lim-default) screen))
   sel-cat (param-read :sel-cat 0)]
  (href :split :split split :step step :ofs ofs :len len :srt srt
               :asc asc :lim lim :sel-ofs sel-ofs :sel-cat sel-cat)))

(defn nav-split [splitn handler params] (let
  [split (hinance.user/splits splitn)
   link (fn [screen] (vector :a {:href (split-href screen
     (if (= handler :split) params {}) {:split splitn :sel-cat 0})}
     (:title split)))]
  (if (and (= handler :split) (= (str splitn) (params :split)))
    [[:li {:class "active"} [:a (:title split)]]]
    [[:li {:class "hidden-sm hidden-md hidden-lg"} (link :xs)]
     [:li {:class "hidden-xs"} (link :sm)]])))

(defn page [handler params content] (vector
  :div {:class "container"}
    [:ul {:class "nav nav-pills"}
      (for [[splitn _] (map-indexed vector hinance.user/splits)
            nav (nav-split splitn handler params)]
       nav)]
    [:div {:class "row"} [:div {:class "col-md-12"} content
       [:hr] [:p {:class "text-muted text-right"}
         "Generated on " hinance.data/timestamp]]]))

(defn amount-str [number cur] (vector :span {:style "white-space:nowrap"}
  (.toLocaleString (* 0.01 number) js/undefined
    (clj->js {:style "currency" :currency cur}))))

(defn date [fmt unixtime]
  (cljs-time.format/unparse
    (cljs-time.format/formatter fmt)
    (cljs-time.coerce/from-long (* 1000 unixtime))))

(defn pick-chgs [changes step ofs len] (let
  [tmin (:time (first changes))
   tfrom (+ tmin (* ofs step)) tto (+ tfrom (* len step))]
  (take-while #(> tto (:time %)) (drop-while #(> tfrom (:time %)) changes))))

(def categ-amounts (memoize (fn [chgsid step categ cofs]
  (map :amount (filter #((:tag-filter categ) (:tags %))
                       (pick-chgs (lookup chgsid) step cofs 1))))))

(def categ-amount (memoize (fn [chgsid step categ cofs amount-ftr]
  (apply + (filter amount-ftr (categ-amounts chgsid step categ cofs))))))

(def categ-amount-total (memoize (fn [chgsid categ]
  (apply + (map :amount (filter #((:tag-filter categ) (:tags %))
    (lookup chgsid)))))))

(def group-index (into (hash-map) (map-indexed (fn [i g] (vector g (str i)))
  (apply sorted-set (map :group
    (concat hinance.data/chgsact hinance.data/chgsplan))))))

(def index-group (clojure.set/map-invert group-index))

(def tag-index (into (hash-map) (map-indexed (fn [i t] (vector t i))
  (apply sorted-set (for
    [change (concat hinance.data/chgsact hinance.data/chgsplan)
     tag (:tags change)] tag)))))

(def index-tag (clojure.set/map-invert tag-index))

(defn chgs-panel [title changes srt asc lim thref-fn th-fn] (let [
  crange (if (<=(count changes)lim) (str " (showing all " (count changes) ")")
    (str " (showing first " (str lim) " out of " (str (count changes)) ")"))
  srt-chgs (take lim (sort-by #((keyword srt) {
    :time (:time %) :label (:label %) :tags (str (sort (:tags %)))
    :group (:group %) :amount (:amount %)}) ({0 > 1 <} asc) changes))
  tdate #(date "yyyy-MM-dd" (:time %))
  tdesc #(if (empty? (:url %)) (:label %) [:a {:href (:url %)} (:label %)])
  ttags #(for [t (sort (:tags %))]
    [:span [:a {:class "btn btn-default" :href (thref-fn {:split 0})}
            (subs (str t) 4)] " "])
  tgrp #(vector :a {:href (href :group :group (group-index (:group %)))}
                   (str (group-index (:group %))))
  tamt #(amount-str (:amount %) (:cur %))
  mobile-only {:class "hidden-sm hidden-md hidden-lg"}
  desktop-only {:class "hidden-xs"}]
  (if (empty? changes) "" (vector :div {:class "panel panel-default"}
    [:div {:class "panel-heading"} [:h3 {:class "panel-title"} title crange]]
    [:table {:class "table table-striped"}
      [:thead desktop-only
        [:tr [:th (th-fn "time" "Date")] [:th (th-fn "label" "Description")]
             [:th (th-fn "tags" "Tags")] [:th (th-fn "group" "Group")]
             [:th {:class "text-right"} (th-fn "amount" "Amount")]]]
      [:tbody desktop-only (for [x srt-chgs]
        [:tr [:td (tdate x)] [:td (tdesc x)] [:td (ttags x)] [:td (tgrp x)]
             [:td {:class "text-right"} (tamt x)]])]
      [:tbody mobile-only (for [x srt-chgs] [:tr [:td
        [:p [:big [:strong (th-fn "time" "Date:") " "] (tdate x)]]
        [:p [:big [:strong (th-fn "label" "Description:") " "] (tdesc x)]]
        [:p [:big [:strong (th-fn "tags" "Tags:") " "] (ttags x)]]
        [:p [:big [:strong (th-fn "group" "Group:") " "] (tgrp x)]]
        [:p [:big [:strong (th-fn "amount" "Amount:") " "] (tamt x)]]]])]]))))

(def chgs-split-panel (memoize (fn [title chgsid split step ofs len srt
                                    asc lim sel-ofs sel-cat] (let [
  params {:split split :step step :ofs ofs :len len :srt srt :asc asc
          :lim lim :sel-ofs sel-ofs :sel-cat sel-cat}
  thref-fn #(split-href nil params %)]
  (hiccups.core/html (chgs-panel title (filter
    #((:tag-filter ((:categs (hinance.user/splits split)) sel-cat))(:tags %))
    (pick-chgs (lookup chgsid) step sel-ofs 1)) srt asc lim thref-fn
    (fn [srt' text] (vector :a {:href (thref-fn 
      {:srt srt' :asc (if (= srt srt') (- 1 asc) 1)})} text))))))))

(defn svg-stack [split step ofs len srt asc lim sel-ofs sel-cat
                 dir column items]
  (if (empty? items) [:g] (let
  [cofs (+ column ofs) [[amount height icat categ] & irest] (seq items)]
  (vector :g
    [:a {:xlink:href (href :split :split split :step step :ofs ofs :len len
                    :srt srt :asc asc :lim lim :sel-ofs cofs :sel-cat icat)}
      [:rect (merge (if (and (= sel-ofs cofs) (= sel-cat icat))
        {:stroke (cfg :sel-col) :stroke-width (str (cfg :sel-width))
         :height (str (- height (* 2 (cfg :sel-width))))
         :y (+ ((dir height) :y) (cfg :sel-width))}
        {:stroke (cfg :bdr-col) :height (str height) :y ((dir height) :y)})
        {:width (str (cfg :cell-width)) :fill (:bg-col categ)
         :rx (str (cfg :bdr-round)) :ry (str (cfg :bdr-round)) :x "0"})]
      [:text {:text-anchor "middle" :fill (:fg-col categ)
              :x (str (cfg :mark-ofs-x))
              :y (str (+ (cfg :mark-ofs-y) ((dir height) :y)))}
        (str amount)]]
    (if (empty? irest) [:g]
      [:g {:transform (str "translate(0," ((dir height) :next-y) ")")}
       (svg-stack split step ofs len srt asc lim sel-ofs sel-cat
                  dir column irest)])))))

(defn stack-up   [h] (hash-map :y (- h) :next-y (- h)))
(defn stack-down [h] (hash-map :y 0     :next-y h))

(defn stack-items [chgsid split step ofs len column ascale amount-ftr sum-ftr]
  (sort-by (comp Math/abs first) < (for
    [[icat categ](map-indexed vector(:categs (hinance.user/splits split))) :let
     [amount (categ-amount chgsid step categ (+ ofs column) amount-ftr)
      height (max (cfg :mark-height) (* ascale (Math/abs amount)))]
     :when (sum-ftr amount)]
    [(int (/ amount 100)) height icat categ])))

(def svg-stack-render (memoize (fn [chgsid dir amount-ftr sum-ftr split step
                            ofs len srt asc lim sel-ofs sel-cat column ascale]
  (hiccups.core/html (svg-stack split step ofs len srt asc lim sel-ofs sel-cat
    dir column (stack-items chgsid split step ofs len column ascale
                            amount-ftr sum-ftr))))))

(defn non-zero? [x] (not (zero? x)))

(defn split-diagram [chgsid posneg split step ofs len
                     srt asc lim sel-ofs sel-cat] (let
  [max-stack-height (fn [ascale amount-ftr sum-ftr] (apply max
    (for [column (range len)] (apply + (map second (stack-items chgsid split
      step ofs len column ascale amount-ftr sum-ftr))))))
   pos-ftrs (if posneg [pos? non-zero?] [non-zero? pos?])
   neg-ftrs (if posneg [neg? non-zero?] [non-zero? neg?])
   norm-height-pos (apply max-stack-height (concat [1] pos-ftrs))
   norm-height-neg (apply max-stack-height (concat [1] neg-ftrs))
   ascale (/ (cfg :amount-scale) (max 1 (+ norm-height-pos norm-height-neg)))
   cells-height-pos (apply max-stack-height (concat [ascale] pos-ftrs))
   cells-height-neg (apply max-stack-height (concat [ascale] neg-ftrs))
   cell-wspace (+ (cfg :cell-width) (cfg :cell-space))
   cells-width (- (* len cell-wspace) (cfg :cell-space))
   total-width (+ (cfg :margin-left) cells-width (cfg :margin-right))
   total-height (+ (cfg :margin-top) cells-height-pos
                   (cfg :mark-space) (cfg :mark-height)
                   (cfg :mark-space) cells-height-neg (cfg :margin-bottom))]
  (vec (concat [:svg {:width "100%"
                      :viewbox (str 0 " " 0 " " total-width " " total-height)}]
    (for [column (range len) :let [
          x (+ (cfg :margin-left) (* column cell-wspace))
          mark-y (+ (cfg :margin-top) cells-height-pos (cfg :mark-space))
          selected (= sel-ofs (+ column ofs))
          sel-ofs-cached (if selected sel-ofs (- 1))
          sel-cat-cached (if selected sel-cat (- 1))]]
     (vector :g
       [:g {:transform (str "translate(" x ","
              (+ (cfg :margin-top) cells-height-pos) ")")}
        (apply svg-stack-render (concat [chgsid stack-up] pos-ftrs
          [split step ofs len srt asc lim sel-ofs-cached sel-cat-cached
           column ascale]))]
       [:rect {:width (str (cfg :cell-width)) :height (str (cfg :mark-height))
               :fill "none" :stroke (cfg :bdr-col) :rx (str (cfg :bdr-round))
               :ry (str (cfg :bdr-round)) :x (str x) :y (str mark-y)}]
       [:text {:text-anchor "middle" :fill (cfg :txt-col)
               :x (str (+ x (cfg :mark-ofs-x)))
               :y (str (+ mark-y (cfg :mark-ofs-y)))}
        (date "YY-MM" (+ (first-time) (* step (+ ofs column))))]
       [:g {:transform (str "translate(" x ","
              (+ mark-y (cfg :mark-height) (cfg :mark-space)) ")")}
        (apply svg-stack-render (concat [chgsid stack-down] neg-ftrs
          [split step ofs len srt asc lim sel-ofs-cached sel-cat-cached
           column ascale]))]))))))

(defn split-labels [chgsid split] (vector
  :ul {:class "list-inline"}
    (for [c (:categs (hinance.user/splits split))]
     [:li [:span {:class "label" :style
       (str "color:" (:fg-col c) ";background-color:" (:bg-col c))}
       (str (:title c) ": " (int (* 0.01
         (categ-amount-total chgsid c))))]])))

(def handlers {
  :home #(vector :h1 "Welcome!")
  :diag #(for [x hinance.data/diag] (list
      [:h3 (:title x) " (" (str (:warns x)) "):"]
      [:pre (clojure.string/join "\n" (:info x))]))
  :group (fn [params] (seq [
    [:h3 (str "Group: " (index-group (params :group)))]
    (for [[cls scrn] [["hidden-sm hidden-md hidden-lg" :xs] ["hidden-xs" :sm]]]
      [:div {:class cls} (for [[title chgs] [["Actual" hinance.data/chgsact]
                                            ["Planned" hinance.data/chgsplan]]]
          (chgs-panel title
            (filter #(= (group-index (:group %)) (params :group)) chgs)
            "time" 0 999 #(split-href scrn {} %) (fn [srt' text] text)))])]))
  :split (fn [params]
          (let [split (cljs.reader/read-string (:split params))
                step (cljs.reader/read-string (:step params))
                ofs (cljs.reader/read-string (:ofs params))
                len (cljs.reader/read-string (:len params))
                srt (:srt params) asc (cljs.reader/read-string (:asc params))
                lim (cljs.reader/read-string (:lim params))
                sel-ofs (cljs.reader/read-string (:sel-ofs params))
                sel-cat (cljs.reader/read-string (:sel-cat params))] (concat
    (if (pos? (warns))
      [[:div {:class "alert alert-warning"}
         [:strong "Warning!"] " There are " (str(warns)) " validation errors ("
         [:a {:href (href :diag)} "read full report"] ")."]] [])
    [(let [
       link (fn [title step ofs sel-ofs]
         (vector :a {:class "btn btn-lg btn-default" :href (href :split
           :split split :step step :ofs ofs :len len :srt srt :asc asc
           :lim lim :sel-ofs sel-ofs :sel-cat sel-cat)} title))
       link-step (fn [title step-new] (let [
         ofs-end-new (int (/ (+ (* (+ ofs len) step) step-new) step-new))
         ofs-new (max 0 (- ofs-end-new len))]
         (link title step-new ofs-new sel-ofs)))]
       (vector :div {:class "btn-group btn-group-lg btn-group-justified"}
         (if (pos? ofs)
           (link "Older" step (max 0 (- ofs len)) sel-ofs)
           [:a {:class "btn btn-lg btn-default disabled"} "Older"])
         (if (= step step-month)
           (link "Actual" (step-actual len) 0 sel-ofs)
           (link-step "Months" step-month))
         (link "Newer" step (+ ofs len) sel-ofs)))
     [:br]
     [:div {:class "panel panel-default"}
       [:div {:class "panel-heading"} [:h3 {:class "panel-title"} "Actual"]]
       [:div {:class "panel-body text-center"}
         (split-diagram :chgsact true split step ofs len srt asc lim
                        sel-ofs sel-cat)
         (split-labels :chgsact split)]]
     [:div {:class "panel panel-default"}
       [:div {:class "panel-heading"} [:h3 {:class "panel-title"}
         "Actual - Planned ="]]
       [:div {:class "panel-body text-center"}
         (split-diagram :chgsdiff false split step ofs len srt asc lim
                        sel-ofs sel-cat)
         (split-labels :chgsdiff split)]]
     [:div {:class "panel panel-default"}
       [:div {:class "panel-heading"} [:h3 {:class "panel-title"} "Planned"]]
       [:div {:class "panel-body text-center"}
         (split-diagram :chgsplan true split step ofs len srt asc lim
                        sel-ofs sel-cat)
         (split-labels :chgsplan split)]]
     (chgs-split-panel "Actual" :chgsact split step ofs len
                       srt asc lim sel-ofs sel-cat)
     (chgs-split-panel "Planned" :chgsplan split step ofs len
                       srt asc lim sel-ofs sel-cat)])))})

(def html-content (memoize (fn [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    (hiccups.core/html (page h ps ((handlers h) ps)))))))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(html! (html-content (.-token %))))
  (doto h (.setEnabled true)))
