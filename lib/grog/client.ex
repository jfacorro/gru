defmodule Grog.Client do
  use GenServer
  alias Grog.Utils

  ## GenServer

  def start_link(module) do
    GenServer.start_link(__MODULE__, [module])
  end

  def init([module]) do
    # Let's trap exits so the terminate/2 callback is called
    Process.flag(:trap_exit, true)
    state = %{client: module.__init__(),
              module: module}
    timeout = wait_timeout(state)
    {:ok, state, timeout}
  end

  def handle_info(:timeout, state) do
    tasks = state.module.__tasks__()
    n = Utils.uniform(length(tasks))
    task_name = Enum.at(tasks, n)
    apply(state.module, task_name, [state.client])

    {:noreply, state, wait_timeout(state)}
  end

  def terminate(_reason, state) do
    state.module.terminate(state.client)
  end

  ## __using__ and its functionality

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [deftask: 2]
      @before_compile Grog.Client
      # Accumulate tasks with their weights
      Module.register_attribute(__MODULE__, :tasks, accumulate: true)

      def __init__ do
        Dict.merge(%{}, unquote(opts))
      end

      def terminate(data) do
        :ok
      end

      defoverridable [terminate: 1]
    end
  end

  defmacro __before_compile__(_env) do
    tasks = Module.get_attribute(__CALLER__.module, :tasks)
            |> Enum.flat_map( fn {name, weight} -> Grog.Utils.repeat(name, weight) end)
            |> Enum.reverse
    quote do
      def __tasks__, do: unquote(tasks)
    end
  end

  defmacro deftask(definition = {name, _, _}, do: contents) do
    quote do
      Grog.Client.__on_definition__(__ENV__, unquote(name))
      def unquote(definition), do: unquote(contents)
    end
  end

  def __on_definition__(env, name) do
    weights = Module.get_attribute(env.module, :weight) || 1
    Module.put_attribute(env.module, :tasks, {name, weights})
  end

  ## Internal functions

  defp wait_timeout state do
    Utils.uniform(state.client.min_wait, state.client.max_wait)
  end
end
