defmodule Grog.Client.Server do
  use GenServer
  alias Grog.Utils

  def start(clients, n, rate) when is_list(clients) do
    GenServer.call(__MODULE__, {:start, clients, n, rate})
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
    {:stopping, Grog.Client.Supervisor.count}
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, new_state, [name: __MODULE__])
  end

  def handle_call({:start, clients, n, rate}, _from, %{status: :stopped}) do
    state = %{status: :running, clients: clients,
              n: n, rate: rate, now: nil}
    {:reply, :ok, state, 0}
  end
  def handle_call({:start, _, _, _}, _from, %{status: :running} = state) do
    reply_with_timeout(state, :busy)
  end
  def handle_call(:status, _from, %{n: 0} = state) do
    {:reply, state.status, state}
  end
  def handle_call(:status, _from, state) do
    reply_with_timeout(state, state.status)
  end

  def handle_cast(:stop, state) do
    Grog.Client.Supervisor.children
    |> Enum.map(&Grog.Client.Supervisor.stop_child/1)

    state = %{state | status: :stopped}
    {:noreply, state}
  end

  def handle_info(:timeout, %{n: 0} = state) do
    {:noreply, state}
  end
  def handle_info(:timeout, state) do
    state.clients
    |> clients_list(min(state.rate, state.n))
    |> Enum.map(&Grog.Client.Supervisor.start_child/1)

    state = %{state
              | n: max(0, state.n - state.rate),
                now: :os.timestamp()}
    {:noreply, state, 1000}
  end

  def new_state() do
    %{status: :stopped, clients: [], n: 0, rate: nil, now: nil}
  end

  ## Internal

  defp clients_list(clients, n) do
    total = Enum.reduce(clients, 0, fn(client, acc) -> acc + client.weight end)
    f = fn client -> Utils.repeat(client, Utils.ceil(client.weight / total * n)) end

    clients
    |> Enum.flat_map(f)
    |> Enum.take(n)
    |> Enum.shuffle
  end

  defp reply_with_timeout(state, reply) do
    diff = :timer.now_diff(:os.timestamp, state.now)
    timeout = round(1000 - diff / 1000)
    {:reply, reply, state, timeout}
  end
end
