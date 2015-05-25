defmodule Grog.HTTP do
  require Logger
  require Grog.Utils
  alias Grog.Utils
  alias Grog.Metric.Server, as: Metric
  alias Grog.Metric.Count
  alias Grog.Metric.CountInterval
  alias Grog.Metric.Average
  alias Grog.Metric.Min
  alias Grog.Metric.Max
  alias Grog.Metric.Percentiles

  @timeout :infinity

  def open(host, port) do
    {:ok, conn} = :shotgun.open(String.to_char_list(host), port)
    conn
  end

  def close(conn) do
    :shotgun.close(conn)
  end

  def get(conn, path, headers \\ %{}, opts \\ %{}) do
    request(conn, :get, path, "", headers, opts)
  end

  def post(conn, path, body, headers \\ %{}, opts \\ %{}) do
    request(conn, :post, path, body, headers, opts)
  end

  def delete(conn, path, body, headers \\ %{}, opts \\ %{}) do
    request(conn, :delete, path, body, headers, opts)
  end

  def put(conn, path, body, headers \\ %{}, opts \\ %{}) do
    request(conn, :put, path, body, headers, opts)
  end

  def options(conn, path, body, headers \\ %{}, opts \\ %{}) do
    request(conn, :options, path, body, headers, opts)
  end

  def head(conn, path, body, headers \\ %{}, opts \\ %{}) do
    request(conn, :head, path, body, headers, opts)
  end

  def request(conn, method, path, body, headers \\ %{}, opts \\ %{}) do
    path_str = String.to_char_list(path)
    opts = Map.put(opts, :timeout, @timeout)
    {time, value} = Utils.time(:shotgun.request(conn, method, path_str, headers, body, opts))

    report_general(time)

    case value do
      {:ok, %{status_code: status_code}} when status_code < 400 ->
        report_success(opts[:name] || path, time)
      {:ok, %{status_code: status_code}} ->
        report_error(opts[:name] || path, status_code)
      {:error, reason} ->
        report_error(:error, reason)
    end

    value
  end

  ## Internal

  defp report_general(time_us) do
    Metric.report(%Count{name: "# Requests"}, 1)
    Metric.report(%CountInterval{name: "# Reqs/sec", interval: 1000}, 1)
    Metric.report(%Percentiles{name: "Total"}, time_us)
  end

  defp report_success(name, time_us) do
    time_ms = time_us / 1000
    Metric.report(%Count{name: name}, 1)
    Metric.report(%Average{name: name}, time_ms)
    Metric.report(%Min{name: name}, time_ms)
    Metric.report(%Max{name: name}, time_ms)
    Metric.report(%CountInterval{name: name, interval: 1000}, 1)

    Metric.report(%Percentiles{name: name}, time_us)
  end

  defp report_error(name, status_code) do
    id = {name, status_code}
    Metric.report(%Count{name: id}, 1)
  end
end
