(defproject hinance_worker "0.1.0-dev"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2629"]]
  :plugins [[lein-cljsbuild "1.0.4"]]
  :cljsbuild {
    :builds [{
      :source-paths ["."]
      :compiler {:output-to "chew.js" :optimizations :advanced}}]})
