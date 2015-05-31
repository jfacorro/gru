(ns gru.core
  (:require [dommy.core :as dom :refer-macros [sel sel1]]))

(enable-console-print!)

(defonce app-state (atom {:status :stopped,
                          :count nil
                          :rate nil
                          :metrics []}))

(defn visible! [elem show?]
  (dom/set-style! elem
                 :display
                 (if show? "inline-block" "none")))

(defn log [x]
  (.log js/console x))

(defn running? [state]
  (= (:status @state) :running))

(defn update-view [state]
  (visible! (sel1 :#stop) (running? state))
  (visible! (sel1 :#start) (not (running? state))))

(defn start [e]
  (swap! app-state assoc :status :running)
  (update-view app-state))

(defn stop [e]
  (swap! app-state assoc :status :stopped)
  (update-view app-state))

(defn init []
  (dom/listen! (sel1 :#start) :click start)
  (dom/listen! (sel1 :#stop) :click stop)
  (update-view app-state))

(init)
