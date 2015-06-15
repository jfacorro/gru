defmodule Gru.Client.Server do
  use GenServer
  alias Gru.Utils

  def start(clients, n, rate) when is_list(clients) do
    case GenServer.call(__MODULE__, {:start, clients, n, rate}) do
      :ok -> :ok
      reason -> {:error, reason}
    end
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
    Gru.Client.Supervisor.count
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
  def handle_call({:start, _, _, _}, _from, state) do
    reply_with_timeout(state, state.status)
  end
  def handle_call(:status, _from, %{n: 0} = state) do
    {:reply, state.status, state}
  end
  def handle_call(:status, _from, state) do
    reply_with_timeout(state, state.status)
  end

  def handle_cast(:stop, state) do
    Task.async &stop_clients/0
    state = %{state | status: :stopping}
    {:noreply, state}
  end

  def handle_info(:timeout, %{n: 0} = state) do
    {:noreply, state}
  end
  def handle_info(:timeout, state) do
    Task.async fn -> start_clients(state) end

    state = %{state
              | n: max(0, state.n - state.rate),
              now: :os.timestamp()}
    {:noreply, state, 1000}
  end
  def handle_info({_, :all_stopped}, state) do
    state = %{state | status: :stopped, n: 0}
    {:noreply, state}
  end
  def handle_info(_, state) do
    reply_with_timeout(state, :noreply)
  end

  ## Internal

  defp new_state() do
    %{status: :stopped, clients: [], n: 0, rate: nil, now: nil}
  end

  defp start_clients(state) do
    state.clients
    |> clients_list(min(state.rate, state.n))
    |> Enum.map(&Gru.Client.Supervisor.start_child/1)
  end

  defp stop_clients do
    Gru.Client.Supervisor.children
    |> Enum.map(&Gru.Client.Supervisor.stop_child/1)

    :all_stopped
  end

  defp clients_list(clients, n) do
    total = Enum.reduce(clients, 0, fn(client, acc) ->
      acc + client.weight
    end)

    f = fn client ->
      Utils.repeat(client, Utils.ceil(client.weight / total * n))
    end

    clients
    |> Enum.flat_map(f)
    |> Enum.take(n)
    |> Enum.shuffle
  end

  defp reply_with_timeout(%{status: :running, n: n} = state, reply) when n > 0 do
    diff = :timer.now_diff(:os.timestamp, state.now)
    timeout = round(1000 - diff / 1000)
    case reply do
      :noreply -> {:noreply, state, timeout}
      _ -> {:reply, reply, state, timeout}
    end
  end
  defp reply_with_timeout(state, reply) do
    case reply do
      :noreply -> {:noreply, state}
      _ -> {:reply, reply, state}
    end
  end
end
