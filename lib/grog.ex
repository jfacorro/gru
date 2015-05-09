defmodule Grog do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    children = [supervisor(Grog.Client.Supervisor, []),
                worker(:ktn_random, [])]
    opts = [strategy: :one_for_one,
            name: Grog.Supervisor]

    {:ok, _pid} = Supervisor.start_link(children, opts)
  end

  def clients_start client, n do
    Logger.info "Starting #{inspect n} #{inspect client}(s)"
    Grog.Utils.repeat(client, n)
    |> Enum.map(&Grog.Client.Supervisor.start_child/1)
  end

  def clients_stop do
    Grog.Client.Supervisor.children()
    |> Enum.map(&Grog.Client.Supervisor.stop_child/1)
  end
end
