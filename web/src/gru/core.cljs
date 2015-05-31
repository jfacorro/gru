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

(defn status [data owner]
  (om/component
   (dom/span nil
             (case (:status data)
               :stopped "Stopped"
               :running "Running"))))

;; Start & Stop

(defn start [data event]
  (om/transact! data :status #(do % :running)))

(defn stop [data event]
  (om/transact! data :status #(do % :stopped)))

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

(om/root start-stop
         app-state
         {:target (dommy/sel1 :#start-stop)})
