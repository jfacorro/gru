defmodule Gru.Minion do
  use GenServer
  alias Gru.Utils

  ## GenServer

  def start_link(module) do
    GenServer.start_link(__MODULE__, [module])
  end

  def init([module]) do
    # Let's trap exits so the terminate/2 callback is called
    Process.flag(:trap_exit, true)
    state = %{minion: module.__init__(),
              module: module}
    timeout = wait_timeout(state)
    {:ok, state, timeout}
  end

  def handle_info(:timeout, state) do
    tasks = state.minion.tasks_module.__tasks__()
    if tasks != [] do
      n = Utils.uniform(length(tasks))
      task_name = Enum.at(tasks, n)
      apply(state.minion.tasks_module, task_name, [state.minion])
    end

    {:noreply, state, wait_timeout(state)}
  end

  def terminate(_reason, state) do
    state.module.terminate(state.minion)
  end

  ## __using__ and its functionality

  defmacro __using__(opts) do
    weight = opts[:weight]
    quote do
      Module.register_attribute(__MODULE__, :minion, persist: true)
      @minion true

      @default %{min_wait: 1000,
                 max_wait: 5000,
                 weight: 10,
                 tasks_module: nil}

      def __init__ do
        data = Dict.merge(@default, unquote(opts))
        init(data)
      end

      def weight do
        unquote(weight)
      end

      def init(data), do: data

      def terminate(data), do: :ok

      defoverridable [init: 1, terminate: 1]
    end
  end

  ## Internal functions

  defp wait_timeout state do
    Utils.uniform(state.minion.min_wait, state.minion.max_wait)
  end
end
