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
    opts = Map.put(opts, :timeout, :infinity)
    {time, value} = Utils.time(:shotgun.request(conn, method, path_str, headers, body, opts))

    report_general()
    case value do
      {:ok, %{status_code: status_code}} when status_code < 400 ->
        report_success(opts[:name] || path, time / 1000)
      {:ok, %{status_code: status_code}} ->
        report_error(opts[:name] || path, status_code)
      {:error, Reason} ->
        report_error(:error, Reason)
    end
    value
  end

  ## Internal

  defp report_general() do
    Metrics.report(%Count{name: "# Requests"}, 1)
    Metrics.report(%CountInterval{name: "# Requests/sec", interval: 1000}, 1)
  end

  defp report_success(name, time_ms) do
    Metrics.report(%Count{name: name}, 1)
    Metrics.report(%Average{name: name}, time_ms)
    Metrics.report(%Min{name: name}, time_ms)
    Metrics.report(%Max{name: name}, time_ms)
  end

  defp report_error(name, status_code) do
    id = {name, status_code}
    Metrics.report(%Count{name: id}, 1)
  end
end
