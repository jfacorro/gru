defmodule Gru do
  require Logger

  def start(minions, n, rate \\ 1)

  @spec start([atom], integer, integer) :: :ok | {:error, any}
  def start(minions, n, rate) when is_list(minions) do
    result = Gru.Minion.Server.start(minions, n, rate)
    case result do
      :ok ->
        Logger.info "Starting #{inspect n} #{inspect minions}(s) at #{inspect rate} minions/sec"
      {:error, reason} ->
        Logger.error "Sorry, but we couldn't start any minions: #{inspect reason}"
    end
    result
  end
  def start(minion, n, rate) when is_atom(minion) do
    start([minion], n, rate)
  end

  def stop do
    Logger.info "Stopping all minions..."
    Gru.Minion.Server.stop()
  end

  def clear do
    Gru.Metric.clear
  end

  def status do
    %{status: Gru.Minion.Server.status,
      count: Gru.Minion.Supervisor.count,
      metrics: Gru.Metric.get_all}
  end
end
