defmodule Grog.Metrics do
  alias Grog.Metrics.Server

  def report(metric, value) do
    Server.report(metric, value)
  end

  def get_all do
    Server.get_all()
  end
end
