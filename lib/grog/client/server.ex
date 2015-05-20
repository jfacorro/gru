defmodule Grog.Client.Server do
  use GenServer
  alias Grog.Utils

  def start(client, n, rate) do
    GenServer.call(__MODULE__, {:start, client, n, rate})
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def handle_call({:start, client, n, rate}, _from, nil) do
    state = %{client: client, n: n, rate: rate, now: nil}
    {:reply, :ok, state, 0}
  end
  def handle_call({:start, _, _, _}, _from, state) do
    diff = :timer.now_diff(:os.timestamp, state.now)
    timeout = round(1000 - diff / 1000)
    {:reply, :busy, state, timeout}
  end
  def handle_call(:stop, _from, _state) do
    count = Grog.Client.Supervisor.count
    Grog.Client.Supervisor.children
    |> Enum.map(&Grog.Client.Supervisor.stop_child/1)

    {:reply, {:ok, count}, nil}
  end

  def handle_info(:timeout, %{n: 0}) do
    {:noreply, nil}
  end
  def handle_info(:timeout, state) do
    IO.inspect(state)
    Utils.repeat(state.client, min(state.rate, state.n))
    |> Enum.map(&Grog.Client.Supervisor.start_child/1)

    state = %{state | n: max(0, state.n - state.rate), now: :os.timestamp()}
    {:noreply, state, 1000}
  end
end
