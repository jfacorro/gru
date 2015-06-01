(ns gru.core
  (:require [dommy.core :as dommy :refer-macros [sel sel1]]
            [om.core :as om]
            [om.dom :as dom]))

(enable-console-print!)

(defonce app-state (atom {:status :stopped,
                          :count nil
                          :rate nil
                          :metrics []}))

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
                           :metrics {:total {:reqs-sec 10}}})))

(defn stop [data _]
  (om/transact! data
                #(merge % {:status :stopped
                           :count nil
                           :rate nil
                           :metrics []})))

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

(om/root status
         app-state
         {:target (dommy/sel1 :#status)})

(om/root (partial number-view [:count])
         app-state
         {:target (dommy/sel1 :#minion-count)})

(om/root (partial number-view [:metrics :total :reqs-sec])
         app-state
         {:target (dommy/sel1 :#reqs-sec)})

(om/root start-stop
         app-state
         {:target (dommy/sel1 :#start-stop)})
