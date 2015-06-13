defmodule Grog do
  require Logger

  def start(clients, n, rate \\ 1)

  def start(clients, n, rate) when is_list(clients) do
    result = Grog.Client.Server.start(clients, n, rate)
    case result do
      :ok ->
        Logger.info "Starting #{inspect n} #{inspect clients}(s) at #{inspect rate} clients/sec"
      :busy ->
        Logger.info "Busy starting other clients."
    end
    result
  end
  def start(client, n, rate) when is_atom(client) do
    start([client], n, rate)
  end

  def stop do
    Logger.info "Stopping all clients..."
    Grog.Client.Server.stop()
  end

  def clear do
    Grog.Metric.Server.clear
  end

  def status do
    %{status: Grog.Client.Server.status,
      count: Grog.Client.Supervisor.count,
      metrics: Grog.Metric.Server.get_all}
  end
end
