(ns hinance.main
  (:require [bidi.bidi] [goog.events] 
    [dommy.core :refer [attr set-attr! remove-attr! append! parent]
                :refer-macros [sel sel1]])
  (:import goog.History goog.history.EventType))

(def routes ["" {"" :home}])

(defn html-param [id param]
  (if (empty? (sel id)) nil (attr (sel1 id) (keyword (str "data-h" param)))))

(defn html-params [id params]
  (into (hash-map) (map #(vector (keyword %) (html-param id %)) params)))

(def hdp (html-params :#hdev-params ["rows"]))
(def hsp (html-params :#hslice-params ["col" "cat"]))

(defn pint [x] (if (nil? x) nil (js/parseInt x)))
(def hdpi (comp pint hdp))
(def hspi (comp pint hsp))
(def attri (comp pint attr))

(defn hide! [x] (set-attr! x :style "display:none"))
(defn show! [x] (remove-attr! x :style))

(defn handle-home! [params] (let
  [colcat (str "col" (hsp :col) "-cat" (hsp :cat))
   cell (str ".hcell-" colcat) cell-act (str ".hcell-act-" colcat)]
  (js/console.log (str cell))
  (js/console.log (str cell-act))
  (dorun (concat (map hide! (sel cell)) (map show! (sel cell-act))))))

(def handlers! {:home handle-home!})

(defn handle! [path]
  (let [m (bidi.bidi/match-route routes path)
        h (m :handler) ps (m :route-params)]
    ((handlers! h) ps)))

(let [h (History.)]
  (goog.events/listen h EventType.NAVIGATE #(handle! (.-token %)))
  (doto h (.setEnabled true)))
