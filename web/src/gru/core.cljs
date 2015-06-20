(ns gru.core
  (:require-macros [cljs.core.async.macros :refer [go go-loop]])
  (:require [dommy.core :as dommy :refer-macros [sel sel1]]
            [om.core :as om]
            [om.dom :as dom]
            [ajax.core :refer [GET POST DELETE]]
            [cljs.core.async :as async]))

(enable-console-print!)

(def api-urls {:status "/api/status"
               :minions "/api/minions"})

(defonce app-state (atom {:status :stopped,
                          :count nil
                          :rate nil
                          :metrics []
                          :total nil}))

(def metrics-keys [:type
                   :name
                   :num_reqs
                   :num_fails
                   :median
                   :average
                   :min
                   :max
                   :content-size
                   :reqs_sec])

(def status-timeout 1000)

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

(defn label-view
  "Creates a label component to display a value whose
  path in the `app-state' atom is specified by `keys'."
  [keys data _]
  (om/component
   (dom/label nil (or (get-in data keys) "n/a"))))

;; Start & Stop

(defn error-handler [{:keys [status status-text]}]
  (js/alert (str "Oops! There was an ERROR: " status " " status-text)))

(defn update-metrics [data response]
  ;;(log (str response))
  ;;(log (:count response))
  (om/transact! data
                #(merge % response)))

(defn metrics-loop [data out]
  (go-loop []
    (let [[value ch] (async/alts! [out (async/timeout status-timeout)])]
      (when (not= value :end)
        (GET (api-urls :status) {:handler (partial update-metrics data)
                            :response-format :edn})
        (recur)))))

(defn start-success [data resp]
  (log resp)
  (let [out (async/chan)]
    (om/transact! data
                  #(merge % {:status :running
                             :status-chan out
                             :count 0
                             :rate 10
                             :metrics []
                             :total {:reqs-sec 10}}))
    (metrics-loop data out)))

(defn start [data _]
  (POST (api-urls :status)
        {:format :edn
         :params {:count 10 :rate 1}
         :handler (partial start-success data)
         :error-handler error-handler}))

(defn stop-success [data resp]
  (log resp)
  (async/put! (@app-state :status-chan) :end)
  (om/transact! data #(merge % {:status :stopped
                                :status-chan nil})))

(defn stop [data _]
  (DELETE (api-urls :status)
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
     (apply dom/tr nil
            (om/build-all col-view values)))))

(defn table-view [data owner]
  (om/component
   (apply dom/tbody nil
          (om/build-all row-view (:metrics data)))))

(om/root status
         app-state
         {:target (dommy/sel1 :#status)})

(om/root (partial label-view [:count])
         app-state
         {:target (dommy/sel1 :#minion-count)})

(om/root (partial label-view [:total :reqs-sec])
         app-state
         {:target (dommy/sel1 :#reqs-sec)})

(om/root start-stop
         app-state
         {:target (dommy/sel1 :#start-stop)})

(om/root table-view
         app-state
         {:target (dommy/sel1 :#metrics)})
