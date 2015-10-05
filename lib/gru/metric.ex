defmodule Gru.Metric do
  def notify(group, metric, value) do
    Gru.Metric.Server.notify(group, metric, value)
  end

  def get_all do
    Gru.Metric.Server.get_all
  end

  def clear do
    Gru.Metric.Server.clear
  end
end
