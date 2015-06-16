defmodule Gru.Minion.Server do
  alias Gru.Utils
  alias Gru.Utils.GenFSM
  use GenFSM, initial_state: :stopped

  def start(minions, n, rate) when is_list(minions) do
    event = {:start, minions, n, rate}
    case GenFSM.sync_send_all_state_event(__MODULE__, event) do
      :ok -> :ok
      reason -> {:error, reason}
    end
  end

  def stop do
    GenFSM.send_all_state_event(__MODULE__, :stop)
    Gru.Minion.Supervisor.count
  end

  def status do
    GenFSM.sync_send_all_state_event(__MODULE__, :status)
  end

  ## GenServer

  def start_link do
    GenFSM.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def stopped({:start, minions, n, rate}, _from, _data) do
    data = %{minions: minions, n: n, rate: rate, now: nil}
    {:reply, :ok, :starting, data, 0}
  end

  ## Starting

  def starting(:timeout, %{n: 0} = data) do
    {:next_state, :running, data}
  end
  def starting(:timeout, data) do
    Task.async fn -> start_minions(data) end

    data = %{data
              | n: max(0, data.n - data.rate),
              now: :os.timestamp()}

    {:next_state, :starting, data, 1000}
  end

  def handle_event(:stop, _state, data) do
    Task.async &stop_minions/0
    {:next_state, :stopping, data}
  end

  def handle_sync_event(_, _from, state = :starting, data) do
    remaining = remaining_timeout(data.now)
    {:reply, state, state, data, remaining}
  end
  def handle_sync_event(:status, _from, state, data) do
    {:reply, state, state, data}
  end
  def handle_sync_event(event = {:start, _, _, _}, from, :stopped, data) do
    stopped(event, from, data)
  end
  def handle_sync_event({:start, _, _, _}, _from, state, data) do
    {:reply, state, state, data}
  end

  def handle_info({_, :all_stopped}, :stopping, data) do
    {:next_state, :stopped, data}
  end
  def handle_info(_, :starting, data) do
    remaining = remaining_timeout(data.now)
    {:next_state, :starting, data, remaining}
  end
  def handle_info(_, state, data) do
    {:next_state, state, data}
  end
  ## Internal

  defp start_minions(state) do
    n = min(state.rate, state.n)
    state.minions
    |> minions_list(n)
    |> Enum.map(&Gru.Minion.Supervisor.start_child/1)
  end

  defp stop_minions do
    Gru.Minion.Supervisor.children
    |> Enum.map(&Gru.Minion.Supervisor.stop_child/1)

    :all_stopped
  end

  defp minions_list(minions, n) do
    total = Enum.reduce(minions, 0, fn(minion, acc) ->
      acc + minion.weight
    end)

    f = fn minion ->
      Utils.repeat(minion, Float.ceil(minion.weight / total * n))
    end

    minions
    |> Enum.flat_map(f)
    |> Enum.take(n)
    |> Enum.shuffle
  end

  defp remaining_timeout(then) do
    diff = :timer.now_diff(:os.timestamp, then)
    round(1000 - diff / 1000)
  end
end
