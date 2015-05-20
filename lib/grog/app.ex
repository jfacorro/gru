defmodule Grog.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [worker(Grog.Client.Server, []),
                supervisor(Grog.Client.Supervisor, []),
                worker(Grog.Metrics.Server, [])]
    opts = [strategy: :one_for_one,
            name: Grog.Supervisor]

    {:ok, _pid} = Supervisor.start_link(children, opts)
  end
end
