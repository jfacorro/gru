(ns gru.core
  (:require-macros [cljs.core.async.macros :refer [go go-loop]])
  (:require [dommy.core :as dommy :refer-macros [sel sel1]]
            [om.core :as om]
            [om.dom :as dom]
            [ajax.core :refer [GET POST DELETE]]
            [cljs.core.async :as async]
            [clojure.string :as str]
            [goog.string :as gstr]
            [goog.string.format]))

(enable-console-print!)

(def api-urls {:status "/api/status"
               :minions "/api/minions"})

(defonce app-state (atom {:status :stopped,
                          :count nil
                          :rate nil
                          :metrics []
                          :total {:name "Total"}}))

(def metrics-keys [:type, :name, :num_reqs, :num_fails,
                   :median, :average, :min, :max,
                   :content-size, :reqs_sec])

(def status-timeout 1000)

(defn log [x]
  (.log js/console x))

;; Status

(defn status [data _]
  (om/component
   (dom/span nil
             (-> data :status name str/capitalize))))

;; Number View

(defn label-view
  "Creates a label component to display a value whose
  path in the `app-state' atom is specified by `keys'."
  ([keys data owner]
   (label-view keys identity data owner))
  ([keys format-fn data owner]
   (om/component
    (dom/label nil (or (as-> (get-in data keys) val
                         (and val (format-fn val)))
                       "n/a")))))

;; Start & Stop

(defn error-handler [{:keys [status status-text]}]
  (js/alert (str "Oops! There was an ERROR: " status " " status-text)))

(defn update-status [data response]
  (when (= :stopped (:status response))
    (async/put! (@app-state :status-chan) :end))

  (om/transact! data
                #(merge % response)))

(defn get-status [data]
  (GET (api-urls :status)
       {:handler (partial update-status data)
        :response-format :edn}))

(defn metrics-loop [data out]
  (go-loop []
    (let [[value ch] (async/alts! [out (async/timeout status-timeout)])]
      (when (not= value :end)
        (get-status data)
        (recur)))))

(defn start-success [data resp]
  (let [out (async/chan)]
    (om/transact! data
                  #(merge % {:status :running
                             :status-chan out}))
    (metrics-loop data out)))

(defn start [data _]
  (POST (api-urls :minions)
        {:format :edn
         :params {:count 10 :rate 1}
         :handler (partial start-success data)
         :error-handler error-handler}))

(defn stop-success [data resp]
  (async/put! (@app-state :status-chan) :end)
  (om/transact! data #(merge % {:status :stopped
                                :status-chan nil})))

(defn stop [data _]
  (DELETE (api-urls :minions)
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
     (stop-button data owner))))

;; Metrics Table

(defmulti format (fn [k _] k))

(defmethod format :type    [_ v] (str/upper-case v))
(defmethod format :median  [_ v] (gstr/format "%.2f" v))
(defmethod format :average [_ v] (gstr/format "%.2f" v))
(defmethod format :min     [_ v] (gstr/format "%.2f" v))
(defmethod format :max     [_ v] (gstr/format "%.2f" v))
(defmethod format :content-size [_ v] (gstr/format "%.2f" v))
(defmethod format :reqs_sec [_ v] (gstr/format "%.2f" v))
(defmethod format :float [_ v] (gstr/format "%.2f" v))
(defmethod format :default [_ v] v)

(defn col-view [data owner]
  (om/component
   (dom/td nil data)))

(defn row-view [data owner]
  (om/component
   (let [values (mapv #(as-> (get data %) v
                         (or (and v (format % v))
                             "n/a"))
                      metrics-keys)]
     (apply dom/tr nil
            (om/build-all col-view values)))))

(defn table-body-view [data owner]
  (om/component
   (apply dom/tbody nil
          (om/build-all row-view (:metrics data)))))

(defn table-footer-view [data owner]
  (row-view (:total data) owner))

(om/root status
         app-state
         {:target (dommy/sel1 :#status)})

(om/root (partial label-view [:count])
         app-state
         {:target (dommy/sel1 :#minion-count)})

(om/root (partial label-view [:total :reqs_sec] (partial format :float))
         app-state
         {:target (dommy/sel1 :#reqs-sec)})

(om/root start-stop
         app-state
         {:target (dommy/sel1 :#start-stop)})

(om/root table-body-view
         app-state
         {:target (dommy/sel1 :#metrics)})

(om/root table-footer-view
         app-state
         {:target (dommy/sel1 :#metrics-total)})
