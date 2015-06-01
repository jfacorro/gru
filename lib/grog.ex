defmodule Grog do
  require Logger

  def start(client, n, rate \\ 1) do
    result = Grog.Client.Server.start(client, n, rate)
    case result do
      :ok ->
        Logger.info "Starting #{inspect n} #{inspect client}(s) at #{inspect rate} clients/sec"
      :busy ->
        Logger.info "Busy starting other clients."
    end
    result
  end

  def stop do
    Logger.info "Stopping all clients..."
    Grog.Client.Server.stop()
  end

  def clear do
    Grog.Metric.Server.clear
  end

  def status do
    %{count: Grog.Client.Supervisor.count,
      metrics: Grog.Metric.Server.get_all}
  end
end
