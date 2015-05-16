defmodule Grog.HTTP do
  use HTTPoison.Base
  require Logger
  require Grog.Utils
  alias Grog.Utils
  alias Grog.Metrics.Server, as: Metrics
  alias Grog.Metrics.Count
  alias Grog.Metrics.Average
  alias Grog.Metrics.Min
  alias Grog.Metrics.Max

  def request(method, url, body \\ "", headers \\ [], opts \\ []) do
    {time, value} = Utils.time(HTTPoison.request(method, url, body, headers, opts))
    report_metrics(opts[:name] || url, time / 1000)
    value
  end

  def request!(method, url, body \\ "", headers \\ [], opts \\ []) do
    {time, value} = Utils.time(HTTPoison.request!(method, url, body, headers, opts))
    report_metrics(opts[:name] || url, time / 1000)
    value
  end

  defp report_metrics(name, time_ms) do
    Metrics.report(%Count{name: name}, 1)
    Metrics.report(%Average{name: name}, time_ms)
    Metrics.report(%Min{name: name}, time_ms)
    Metrics.report(%Max{name: name}, time_ms)
  end
end
