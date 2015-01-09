(defproject hinance-worker "0.1.0-dev"
  :description "Hinance worker module."
  :url "https://github.com/olegus8/hinance"
  :license {:name "The MIT License"
            :url "https://github.com/olegus8/hinance/blob/master/LICENSE"}
  :plugins [[lein-cljsbuild "1.0.4"]]
  :dependencies [[org.clojure/clojurescript "0.0-2629"]]
  :cljsbuild {
    :builds [{
      :source-paths ["."]
      :compiler {:output-to "chew.js" :optimizations :advanced}}]})
