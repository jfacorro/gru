defmodule Gru.Metric.Worker do
  use GenServer
  alias Gru.Utils, as: Utils
  import Gru.Metric.Protocol, only: [accumulate: 2]

  ## API

  def update(pid, value) do
    GenServer.call(pid, {:update, value})
  end

  ## GenServer

  def start_link(metric, value) do
    GenServer.start_link(__MODULE__, [metric, value])
  end

  def init([metric, value]) do
    # IO.inspect {:init, self, value}
    table = Utils.struct_type(metric)
    do_init(table, metric, value)
    {:ok, %{table: table, metric: metric}}
  end

  def handle_call({:update, value}, _from, state) do
    # IO.inspect {:update, self, value}
    %{table: table, metric: metric} = state
    do_update(table, metric, value)
    {:reply, :ok, state}
  end

  ## Internal

  defp do_init(table, metric, value) do
    metric = accumulate(metric, value)
    :ets.insert(table, {self(), metric})
  end

  defp do_update(table, metric, value) do
    try do
      metric = :ets.lookup_element(table, self(), 2)
      |> accumulate(value)

      :ets.insert(table, {self(), metric})
    catch
      _, :badarg ->
        do_init(table, metric, value)
    end
  end
end
