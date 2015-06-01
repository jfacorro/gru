(ns gru.core
  (:require [dommy.core :as dommy :refer-macros [sel sel1]]
            [om.core :as om]
            [om.dom :as dom]))

(enable-console-print!)

(defonce app-state (atom {:status :stopped,
                          :count nil
                          :rate nil
                          :metrics [{:type "GET"
                                     :name "/status"},
                                    {:type "POST"
                                     :name "/token"}]
                          :total nil}))

(def metrics-keys [:type
                   :name
                   :num-reqs
                   :num-fails
                   :median
                   :average
                   :min
                   :max
                   :content-size
                   :reqs-sec])

(defn log [x]
  (.log js/console x))

;; Status

(defn status [data _]
  (om/component
   (dom/span nil
             (case (:status data)
               :stopped "Stopped"
               :running "Running"))))

;; Number View

(defn number-view [keys data _]
  (om/component
   (dom/label nil (or (get-in data keys) "n/a"))))

;; Start & Stop

(defn start [data _]
  (om/transact! data
                #(merge % {:status :running
                           :count 1000
                           :rate 10
                           :metrics []
                           :total {:reqs-sec 10}})))

(defn stop [data _]
  (om/transact! data
                #(merge % {:status :stopped
                           :count nil
                           :rate nil})))

(defn start-button [data owner]
  (dom/button #js {:className "btn btn-success"
                   :onClick (partial start data)}
              "Start"))

(defn stop-button [data owner]
  (dom/button #js {:className "btn btn-danger"
                   :onClick (partial stop data)}
              "Stop"))

(defn start-stop [data owner]
  (om/component
   (case (:status data)
     :stopped (start-button data owner)
     :running (stop-button data owner))))

(defn col-view [data owner]
  (om/component (dom/td nil data)))

(defn row-view [data owner]
  (om/component
   (let [values (mapv #(get data %) metrics-keys)]
     (println values)
     (apply dom/tr nil
            (om/build-all col-view values)))))

(defn table-view [data owner]
  (om/component
   (apply dom/tbody nil
          (om/build-all row-view (:metrics data)))))

(om/root status
         app-state
         {:target (dommy/sel1 :#status)})

(om/root (partial number-view [:count])
         app-state
         {:target (dommy/sel1 :#minion-count)})

(om/root (partial number-view [:total :reqs-sec])
         app-state
         {:target (dommy/sel1 :#reqs-sec)})

(om/root start-stop
         app-state
         {:target (dommy/sel1 :#start-stop)})

(om/root table-view
         app-state
         {:target (dommy/sel1 :#metrics)})
