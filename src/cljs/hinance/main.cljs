(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr! remove-attr!] :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/" {"diag" :diag "group" :group
  ["slice/sel-ofs." :sel-ofs "/sel-cat." :sel-cat] :slice}}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn html-param [id param]
  (if (empty? (sel id)) nil (attr (sel1 id) (keyword (str "data-h" param)))))

(defn html-params [id params]
  (into (hash-map) (map #(vector (keyword %) (html-param id %)) params)))

(def hdp (html-params :#hdev-params ["defstep" "name" "len"]))
(def hsp (html-params :#hslice-params ["slice" "step"]))

(def hdpi (comp js/parseInt hdp))
(def hspi (comp js/parseInt hsp))
(def attri (comp js/parseInt attr))

(defn hide! [x] (set-attr! x :style "display:none"))
(defn show! [x] (remove-attr! x :style))

(defn slice-href [dev slice step ofs sel-ofs sel-cat]
  (str dev "-slice" slice "-step" step "-ofs" ofs ".html"
    (href :slice :sel-ofs sel-ofs :sel-cat sel-cat)))

(defn set-hnav-href! [li] (let [a (sel1 li :a) n (attr li :data-hslice)
  s (or (hsp :step) (hdp :defstep)) d (hdp :name) so (- (hdpi :len) 1)]
  (set-attr! a :href (slice-href d n s 0 so 0))
  (identity li)))

(defn set-hstep-href! [a] (let [d (hdp :name) n (hsp :slice)
  s (attr a :data-hstep) o (attri a :data-hofs) so (+ o (- (hdpi :len) 1))]
  (set-attr! a :href (slice-href d n s o so 0))))

(defn set-hofs-href! [a] (let [d (hdp :name) n (hsp :slice)
  s (hsp :step) o (attri a :data-hofs) so (+ o (- (hdpi :len) 1))]
  (set-attr! a :href (slice-href d n s o so 0))))

(defn handle-home! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map set-hnav-href!) (map show!)))))

(defn handle-slice! [params] (let
  [curn? #(= (attr % :data-hslice) (hsp :slice))
   curs? #(= (attr % :data-hstep) (hsp :step))
   curc? #(and (= (attr % :data-hofs) (params :sel-ofs))
               (= (attr % :data-hcateg) (params :sel-cat)))] (dorun (concat
  (->> (sel :.hnav-active) (map #((if (curn? %) show! hide!) %)))
  (->> (sel :.hnav) (map #((if(curn? %)hide! show!)%)) (map set-hnav-href!))
  (->> (sel :.hcell-active) (map #((if (curc? %) show! hide!) %)))
  (->> (sel :.hcell) (map #((if (curc? %) hide! show!) %)))
  (->> (sel :.hstep) (map #((if(curs? %)hide! show!)%)) (map set-hstep-href!))
  (->> (sel :.hofs) (map set-hofs-href!))))))

(def handlers! {
  :home handle-home!
  :diag #(js/console.log "diag")
  :group #(js/console.log "group")
  :slice handle-slice!})

(defn handle! [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    ((handlers! h) ps)))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
