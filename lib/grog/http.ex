defmodule Grog.HTTP do
  require Logger
  require Grog.Utils
  alias Grog.Utils
  alias Grog.Metrics.Server, as: Metrics
  alias Grog.Metrics.Count
  alias Grog.Metrics.CountInterval
  alias Grog.Metrics.Average
  alias Grog.Metrics.Min
  alias Grog.Metrics.Max

  def open(host, port) do
    {:ok, conn} = :shotgun.open(String.to_char_list(host), port)
    conn
  end

  def close(conn) do
    :shotgun.close(conn)
  end

  def get(conn, path, headers \\ %{}, opts \\ %{}) do
    path_str = String.to_char_list(path)
    {time, value} = Utils.time(:shotgun.get(conn, path_str, headers, opts))
    report_metrics(opts[:name] || path, time / 1000)
    value
  end

  defp report_metrics(name, time_ms) do
    Metrics.report(%Count{name: "# Requests"}, 1)
    Metrics.report(%CountInterval{name: "# Requests/sec", interval: 1000}, 1)

    Metrics.report(%Count{name: name}, 1)
    Metrics.report(%Average{name: name}, time_ms)
    Metrics.report(%Min{name: name}, time_ms)
    Metrics.report(%Max{name: name}, time_ms)
  end
end
