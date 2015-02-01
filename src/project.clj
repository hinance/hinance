(defproject hinance "0.0.0"
  :dependencies [[bidi "1.12.0"]
                 [com.andrewmcveigh/cljs-time "0.3.0"]
                 [hiccups "0.3.0"]
                 [org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2665"]]
  :plugins [[lein-cljsbuild "1.0.4"]]
  :cljsbuild {
    :builds [{
      :source-paths ["cljs"]
      :compiler {:output-to "hinance.js" :optimizations :advanced}}]})
