defmodule Grog.Client.Server do
  use GenServer
  require Logger

  def start_link module do
    GenServer.start_link(__MODULE__, [module])
  end

  def init([module]) do
    # Logger.info("Initializing '#{inspect module}' client...")
    # Let's trap exits so the terminate/2 callback is called
    Process.flag(:trap_exit, true)
    state = %{client: module.__init__(),
              module: module}
    {:ok, state, wait_timeout(state)}
  end

  def handle_info :timeout, state do
    tasks = state.module.__tasks__()
    n = :ktn_random.integer(length(tasks))
    task_name = Enum.at(tasks, n)
    apply(state.module, task_name, [state.client])

    {:noreply, state, wait_timeout(state)}
  end

  def terminate(_reason, _state) do
    # Logger.info("Terminating '#{state.client.name}' client...")
  end

  ## Internal functions

  defp wait_timeout state do
    :ktn_random.integer(state.client.min_wait, state.client.max_wait)
  end
end
