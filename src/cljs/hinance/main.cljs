(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr! remove-attr! parent]
                :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home "/"
  {"diag" :diag
   ["group/srt." :srt "/asc." :asc] :group
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

(defn group-href-local [args]
  (href :group :srt (args :srt) :asc (args :asc)))

(defn group-href [args]
  (str (args :dev) "-group" (args :grp) ".html" (group-href-local args)))

(defn diag-href [args] (str (args :dev) "-diag.html" (href :diag)))

(defn set-hnav-href! [params li] (let
  [a (sel1 li :a) ofs (or (hspi :ofs) 0)
   href-args {:dev (hdp :name) :slice (attr li :data-hslice)
     :step (or (hsp :step) (hdp :defstep)) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0
     :srt (if (nil? params) "date" (params :srt))
     :asc (if (nil? params) 0 (params :asc))}]
  (set-attr! a :href (slice-href href-args))
  (identity li)))

(defn set-hcell-href! [params rect] (let
  [a (parent rect)
   href-args {:sel-ofs (attr rect :data-hofs) :sel-cat (attr rect :data-hcateg)
     :srt (params :srt) :asc (params :asc)}]
  (set-attr! a :xlink:href (slice-href-local href-args))
  (identity rect)))

(defn set-hstep-href! [params a] (let
  [ofs (attri a :data-hofs)
   href-args {
     :dev (hdp :name) :slice (hsp :slice) :step (attr a :data-hstep) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt (params :srt)
     :asc (params :asc)}]
  (set-attr! a :href (slice-href href-args))))

(defn set-hofs-href! [params a] (let
  [ofs (attri a :data-hofs)
   href-args {
     :dev (hdp :name) :slice (hsp :slice) :step (hsp :step) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt (params :srt)
     :asc (params :asc)}]
  (set-attr! a :href (slice-href href-args))))

(defn set-htag-href! [params a] (let
  [ofs (or (hspi :ofs) 0)
   href-args {
     :dev (hdp :name) :slice (attr a :data-htag)
     :step (or (hsp :step) (hdp :defstep)) :ofs ofs
     :sel-ofs (+ ofs (- (hdpi :len) 1)) :sel-cat 0 :srt (params :srt)
     :asc (params :asc)}]
  (set-attr! a :href (slice-href href-args))))

(defn set-slice-hsrt-href! [params a] (let
  [hsrt (attr a :data-hsrt)
   href-args {
     :sel-ofs (params :sel-ofs) :sel-cat (params :sel-cat)
     :srt hsrt :asc (if (= hsrt (params :srt)) (- 1 (pint (params :asc))) 0)}]
  (set-attr! a :href (slice-href-local href-args))))

(defn set-group-hsrt-href! [params a] (let
  [hsrt (attr a :data-hsrt)
   href-args {
     :srt hsrt :asc (if (= hsrt (params :srt)) (- 1 (pint (params :asc))) 0)}]
  (set-attr! a :href (group-href-local href-args))))

(defn set-hgrp-href! [params a] (let
  [href-args {
    :dev (hdp :name) :grp (attr a :data-hgrp)
    :srt (params :srt) :asc (params :asc)}]
  (set-attr! a :href (group-href href-args))))

(defn set-hdiag-href! [a]
  (set-attr! a :href (diag-href {:dev (hdp :name)})))

(defn update-htable! [params div] (dorun (concat
  (->> (sel div :.hgrp) (map (partial set-hgrp-href! params)))
  (->> (sel div :.hsrt) (map (partial set-slice-hsrt-href! params)))
  (->> (sel div :.htag) (map (partial set-htag-href! params)))))
  (identity div))

(defn handle-home! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map (partial set-hnav-href! params)) (map show!)))))

(defn handle-diag! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map (partial set-hnav-href! params)) (map show!)))))

(defn handle-group! [params] (dorun (concat
  (->> (sel :.hnav-active) (map hide!))
  (->> (sel :.hnav) (map (partial set-hnav-href! params)) (map show!))
  (->> (sel :.hgrp) (map (partial set-hgrp-href! params)))
  (->> (sel :.hsrt) (map (partial set-group-hsrt-href! params)))
  (->> (sel :.htag) (map (partial set-htag-href! params))))))

(defn handle-slice! [params] (let
  [curn? #(= (attr % :data-hslice) (hsp :slice))
   curs? #(= (attr % :data-hstep) (hsp :step))
   curc? #(and (= (attr % :data-hofs) (params :sel-ofs))
               (= (attr % :data-hcateg) (params :sel-cat)))] (dorun (concat
  (->> (sel :.hnav-active) (map #((if (curn? %) show! hide!) %)))
  (->> (sel :.hnav) (map #((if(curn? %)hide! show!)%))
                    (map (partial set-hnav-href! params)))
  (->> (sel :.hdiag) (map set-hdiag-href!))
  (->> (sel :.hcell-active) (map #((if (curc? %) show! hide!) %)))
  (->> (sel :.hcell) (map #((if(curc? %)hide! show!)%))
                     (map (partial set-hcell-href! params)))
  (->> (sel :.hstep) (map #((if(curs? %)hide! show!)%))
                     (map (partial set-hstep-href! params)))
  (->> (sel :.hofs) (map (partial set-hofs-href! params)))
  (->> (sel :.htable)
       (map #((if(curc? %)(comp(partial update-htable! params)show!)hide!)%))
  )))))

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
