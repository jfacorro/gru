(defproject gru "0.1.0-SNAPSHOT"
  :description "FIXME: write this!"
  :url "http://example.com/FIXME"

  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2755"]

                 [org.omcljs/om "0.8.8"]
                 [cljs-ajax "0.3.12"]
                 [prismatic/dommy "1.1.0"]]

  :node-dependencies [[source-map-support "0.2.8"]]

  :plugins [[lein-cljsbuild "1.0.4"]
            [lein-npm "0.4.0"]]

  :source-paths ["src" "target/classes"]

  :clean-targets ["js" "js-adv"]

  :cljsbuild {
    :builds [{:id "dev"
              :source-paths ["src"]
              :compiler {
                :main gru.core
                :output-to "js/gru.js"
                :output-dir "js"
                :optimizations :none
                :cache-analysis true
                :source-map true}}
             {:id "release"
              :source-paths ["src"]
              :compiler {
                :main gru.core
                :output-to "js-adv/gru.min.js"
                :output-dir "js-adv"
                :optimizations :advanced
                :pretty-print false}}]})
