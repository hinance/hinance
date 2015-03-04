(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr! remove-attr! parent]
                :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/" {"diag" :diag "group" :group
  ["slice/sel-ofs." :sel-ofs "/sel-cat." :sel-cat
   "/srt." :srt "/asc." :asc] :slice}}])

(defn href [& args] (str "#" (apply bidi.bidi/path-for routes args)))

(defn html-param [id param]
  (if (empty? (sel id)) nil (attr (sel1 id) (keyword (str "data-h" param)))))

(defn html-params [id params]
  (into (hash-map) (map #(vector (keyword %) (html-param id %)) params)))

(def hdp (html-params :#hdev-params ["defstep" "name" "len"]))
(def hsp (html-params :#hslice-params ["slice" "step" "ofs"]))

(defn pint [x] (if (nil? x) nil (js/parseInt x)))
(def hdpi (comp pint hdp))
(def hspi (comp pint hsp))
(def attri (comp pint attr))

(defn hide! [x] (set-attr! x :style "display:none"))
(defn show! [x] (remove-attr! x :style))

(defn slice-href-local [args]
  (href :slice :sel-ofs (args :sel-ofs) :sel-cat (args :sel-cat)
               :srt (args :srt) :asc (args :asc)))

(defn slice-href [args]
  (str (args :dev) "-slice" (args :slice) "-step"
       (args :step) "-ofs" (args :ofs) ".html" (slice-href-local args)))

(defn group-href [args]
  (str (args :dev) "-group" (args :grp) ".html" (href :group)))

(defn diag-href [args] (str (args :dev) "-diag.html" (href :diag)))

(defn set-hnav-href! [li] (let
  [a (sel1 li :a) ofs (or (hspi :ofs) 0)
   href-args {:dev (hdp :name) :slice (attr li :data-hslice)
     :step (or (hsp :step) (hdp :defstep)) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt "date" :asc 0}]
  (set-attr! a :href (slice-href href-args))
  (identity li)))

(defn set-hcell-href! [rect] (let
  [a (parent rect)
   href-args {:sel-ofs (attr rect :data-hofs) :sel-cat (attr rect :data-hcateg)
     :srt "date" :asc 0}]
  (set-attr! a :xlink:href (slice-href-local href-args))
  (identity rect)))

(defn set-hstep-href! [a] (let
  [ofs (attri a :data-hofs)
   href-args {
     :dev (hdp :name) :slice (hsp :slice) :step (attr a :data-hstep) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt "date" :asc 0}]
  (set-attr! a :href (slice-href href-args))))

(defn set-hofs-href! [a] (let
  [ofs (attri a :data-hofs)
   href-args {
     :dev (hdp :name) :slice (hsp :slice) :step (hsp :step) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt "date" :asc 0}]
  (set-attr! a :href (slice-href href-args))))

(defn set-htag-href! [a] (let
  [ofs (or (hspi :ofs) 0)
   href-args {
     :dev (hdp :name) :slice (attr a :data-htag)
     :step (or (hsp :step) (hdp :defstep)) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt "date" :asc 0}]
  (set-attr! a :href (slice-href href-args))))

(defn set-hgrp-href! [a] (let
  [href-args {
    :dev (hdp :name) :grp (attr a :data-hgrp)}]
  (set-attr! a :href (group-href href-args))))

(defn set-hdiag-href! [a]
  (set-attr! a :href (diag-href {:dev (hdp :name)})))

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
