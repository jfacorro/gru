(ns gru.core
  (:require [dommy.core :as dommy :refer-macros [sel sel1]]
            [om.core :as om]
            [om.dom :as dom]
            [ajax.core :refer [GET POST DELETE]]))

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

(defn error-handler [{:keys [status status-text]}]
  (js/alert (str "Oops! There was an ERROR: " status " " status-text)))

(defn start-success [data resp]
  (log resp)
  (om/transact! data
                #(merge % {:status :running
                           :count 1000
                           :rate 10
                           :metrics []
                           :total {:reqs-sec 10}})))

(defn start [data _]
  (POST "/api/clients"
        {:format :edn
         :params {:count 10 :rate 1}
         :handler (partial start-success data)
         :error-handler error-handler}))

(defn stop-success [data resp]
  (log resp)
  (om/transact! data #(merge % {:status :stopped})))

(defn stop [data _]
  (DELETE "/api/clients"
          {:handler (partial stop-success data)
           :error-handler error-handler}))

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

;; Metrics Table

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
