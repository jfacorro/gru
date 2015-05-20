defmodule Grog.Client.Server do
  use GenServer
  alias Grog.Utils

  def start(client, n, rate) do
    GenServer.cast(__MODULE__, {:start, client, n, rate})
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def handle_cast({:start, client, n, rate}, _) do
    state = %{client: client, n: n, rate: rate}
    {:noreply, state, 0}
  end
  def handle_cast(:stop, state) do
    Grog.Client.Supervisor.children()
    |> Enum.map(&Grog.Client.Supervisor.stop_child/1)

    {:noreply, state}
  end

  def handle_info(:timeout, %{n: 0}) do
    {:noreply, nil}
  end
  def handle_info(:timeout, state) do
    Utils.repeat(state.client, min(state.rate, state.n))
    |> Enum.map(&Grog.Client.Supervisor.start_child/1)

    state = %{state | n: max(0, state.n - state.rate)}
    {:noreply, state, 1000}
  end
end
