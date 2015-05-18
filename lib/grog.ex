defmodule Grog do
  require Logger

  def start(client, n \\ 1000) do
    Logger.info "Starting #{inspect n} #{inspect client}(s)"
    Grog.Utils.repeat(client, n)
    |> Enum.map(&Grog.Client.Supervisor.start_child/1)
  end

  def stop do
    Grog.Client.Supervisor.children()
    |> Enum.map(&Grog.Client.Supervisor.stop_child/1)
  end

  def status do
    info = Process.info(Process.whereis(Grog.Metrics.Server))
    %{clients_count: Grog.Client.Supervisor.count.active,
      queue_len: info[:message_queue_len],
      metrics: Grog.Metrics.Server.get_all}
  end
end
