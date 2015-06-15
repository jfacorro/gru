defmodule Gru.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [worker(Gru.Minion.Server, []),
                supervisor(Gru.Minion.Supervisor, []),
                worker(Gru.Metric.Server, [])]
    opts = [strategy: :one_for_one,
            name: Gru.Supervisor]

    {:ok, _pid} = Supervisor.start_link(children, opts)
  end
end
