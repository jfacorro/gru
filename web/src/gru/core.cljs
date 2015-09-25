(ns gru.core
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]
                   [om.core :refer [component]])
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

(defn status-view [data _]
  (component
   (dom/span nil
             (-> data :status name str/capitalize))))

;; Number View

(defn label-view
  "Creates a label component to display a value whose
  path in the `app-state' atom is specified by `keys'."
  ([keys data owner]
   (label-view keys identity data owner))
  ([keys format-fn data owner]
   (component
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

(defn get-status [handler]
  (GET (api-urls :status)
       {:handler handler
        :response-format :edn}))

(defn metrics-loop [data out]
  (go-loop []
    (let [[value ch] (async/alts! [out (async/timeout status-timeout)])]
      (when (not= value :end)
        (get-status (partial update-status data))
        (recur)))))

(defn start-success
  [data _]
  (let [out (async/chan)]
    (om/transact! data #(merge % {:status-chan out}))
    (metrics-loop data out)))

(defn start
  [data _]
  (POST (api-urls :minions)
        {:format :edn
         :params {:count (:count data)
                  :rate  (:rate data)}
         :handler (partial start-success data)
         :error-handler error-handler}))

(defn stop-success
  [data _resp]
  (get-status (partial update-status data)))

(defn stop
  [data _]
  (DELETE (api-urls :minions)
          {:handler (partial stop-success data)
           :error-handler error-handler}))

(defn start-button [data owner]
  (dom/button #js {:className "btn btn-success"
                   :data-toggle "modal"
                   :data-target ".start-options"}
              "Start"))

(defn stop-button [data owner]
  (dom/button #js {:className "btn btn-danger"
                   :onClick (partial stop data)}
              "Stop"))

(defn start-stop-view [data owner]
  (component
   (case (:status data)
     :stopped (start-button data owner)
     (stop-button data owner))))

;; Clear

(defn clear
  [data event]
  (DELETE (api-urls :status)
          {:handler (partial update-status data)
           :response-format :edn}))

(defn clear-button
  [data _]
  (dom/button #js {:className "btn btn-warning"
                   :onClick (partial clear data)}
              "Clear"))

(defn clear-view
  [data owner]
  (component
   (case (:status data)
     :stopped (dom/span nil nil)
     (clear-button data owner))))

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
  (component
   (dom/td nil data)))

(defn row-view [data owner]
  (component
   (let [values (mapv #(as-> (get data %) v
                         (or (and v (format % v))
                             "n/a"))
                      metrics-keys)]
     (apply dom/tr nil
            (om/build-all col-view values)))))

(defn table-body-view [data owner]
  (component
   (apply dom/tbody nil
          (om/build-all row-view (:metrics data)))))

(defn table-footer-view [data owner]
  (row-view (:total data) owner))

(om/root status-view
         app-state
         {:target (dommy/sel1 :#status)})

(om/root (partial label-view [:count])
         app-state
         {:target (dommy/sel1 :#minion-count)})

(om/root (partial label-view [:total :reqs_sec] (partial format :float))
         app-state
         {:target (dommy/sel1 :#reqs-sec)})

(om/root clear-view
         app-state
         {:target (dommy/sel1 :#clear)})

(om/root start-stop-view
         app-state
         {:target (dommy/sel1 :#start-stop)})

(om/root table-body-view
         app-state
         {:target (dommy/sel1 :#metrics)})

(om/root table-footer-view
         app-state
         {:target (dommy/sel1 :#metrics-total)})

(defn init [data response]
  (when-not (= :stopped (:status response))
    (start-success data :ok)))

(defn int-from-input [id]
  (-> id sel1 (.-value) js/parseInt))

(defn start-options []
  (let [count (int-from-input :#minion-count-txt)
        rate  (int-from-input :#minion-rate-txt)]
    {:count count
     :rate rate}))

(defn start-handler [e]
  (let [opts   (start-options)
        _      (swap! app-state merge opts)
        cursor (om/root-cursor app-state)]
    (start cursor e)))

(defn main []
  (->> (om/root-cursor app-state)
       (partial init)
       get-status)

  (dommy/listen! (dommy/sel1 :#go-btn)
                 :click start-handler))

(main)
