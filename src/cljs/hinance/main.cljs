(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr! remove-attr! parent]
                :refer-macros [sel sel1]])
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

(defn slice-href-local [sel-ofs sel-cat]
  (href :slice :sel-ofs sel-ofs :sel-cat sel-cat))

(defn slice-href [dev slice step ofs & args]
  (str dev "-slice" slice "-step" step "-ofs" ofs ".html"
    (apply slice-href-local args)))

(defn group-href [dev grp] (str dev "-group" grp ".html" (href :group)))

(defn diag-href [dev] (str dev "-diag.html" (href :diag)))

(defn set-hnav-href! [li] (let [a (sel1 li :a) n (attr li :data-hslice)
  s (or (hsp :step) (hdp :defstep)) d (hdp :name) so (- (hdpi :len) 1)]
  (set-attr! a :href (slice-href d n s 0 so 0))
  (identity li)))

(defn set-hcell-href! [rect] (let
  [a (parent rect) so (attr rect :data-hofs) sc (attr rect :data-hcateg)]
  (set-attr! a :xlink:href (slice-href-local so sc))
  (identity rect)))

(defn set-hstep-href! [a] (let [d (hdp :name) n (hsp :slice)
  s (attr a :data-hstep) o (attri a :data-hofs) so (+ o (- (hdpi :len) 1))]
  (set-attr! a :href (slice-href d n s o so 0))))

(defn set-hofs-href! [a] (let [d (hdp :name) n (hsp :slice)
  s (hsp :step) o (attri a :data-hofs) so (+ o (- (hdpi :len) 1))]
  (set-attr! a :href (slice-href d n s o so 0))))

(defn set-htag-href! [a] (let
  [d (hdp :name) n (attr a :data-htag) s (or (hsp :step) (hdp :defstep))
   o (or (hspi :hofs) 0) so (+ o (- (hdpi :len) 1))]
  (set-attr! a :href (slice-href d n s o so 0))))

(defn set-hgrp-href! [a]
  (set-attr! a :href (group-href (hdp :name) (attr a :data-hgrp))))

(defn set-hdiag-href! [a]
  (set-attr! a :href (diag-href (hdp :name))))

(defn update-htable! [div] (dorun (concat
  (->> (sel div :.hgrp) (map set-hgrp-href!))
  (->> (sel div :.htag) (map set-htag-href!))))
  (identity div))

(defn handle-home! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map set-hnav-href!) (map show!)))))

(defn handle-diag! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map set-hnav-href!) (map show!)))))

(defn handle-group! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map set-hnav-href!) (map show!))
  (->> (sel :.hgrp) (map set-hgrp-href!))
  (->> (sel :.htag) (map set-htag-href!)))))

(defn handle-slice! [params] (let
  [curn? #(= (attr % :data-hslice) (hsp :slice))
   curs? #(= (attr % :data-hstep) (hsp :step))
   curc? #(and (= (attr % :data-hofs) (params :sel-ofs))
               (= (attr % :data-hcateg) (params :sel-cat)))] (dorun (concat
  (->> (sel :.hnav-active) (map #((if (curn? %) show! hide!) %)))
  (->> (sel :.hnav) (map #((if(curn? %)hide! show!)%)) (map set-hnav-href!))
  (->> (sel :.hdiag) (map set-hdiag-href!))
  (->> (sel :.hcell-active) (map #((if (curc? %) show! hide!) %)))
  (->> (sel :.hcell) (map #((if(curc? %)hide! show!)%)) (map set-hcell-href!))
  (->> (sel :.hstep) (map #((if(curs? %)hide! show!)%)) (map set-hstep-href!))
  (->> (sel :.hofs) (map set-hofs-href!))
  (->> (sel :.htable)
       (map #((if (curc? %) (comp update-htable! show!) hide!) %)))))))

(def handlers! {
  :home handle-home!
  :diag handle-diag!
  :group handle-group!
  :slice handle-slice!})

(defn handle! [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    ((handlers! h) ps)))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
