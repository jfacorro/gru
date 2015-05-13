defmodule Grog.Metrics.Server do
  use GenServer
  require Logger
  alias Grog.Metrics.Metric

  @datastore __MODULE__

  ## API

  def report(metric, value) do
    GenServer.cast(__MODULE__, {:report, metric, value})
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Logger.info("Starting #{inspect __MODULE__}")
    create_table(@datastore)
    {:ok, {}}
  end

  def handle_call({:get, name}, _from, state) do
    {:reply, lookup(@datastore, name), state}
  end
  def handle_call(:get_all, _from, state) do
    {:reply, get_all(@datastore), state}
  end

  def handle_cast({:report, metric, value}, state) do
    name = Metric.name(metric)
    metrics = lookup(@datastore, name) || %{}

    metric_type = metric.__struct__
    metric = Map.get(metrics, metric_type, metric)
    metric = Metric.accumulate(metric, value)

    metrics = Map.put(metrics, metric_type, metric)
    insert(@datastore, name, metrics)

    {:noreply, state}
  end
  def handle_cast(:clear, state) do
    delete_all(@datastore)
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    Logger.info("Terminating '#{inspect __MODULE__}'")
  end

  ## Internal

  defp create_table(name) do
    :ets.new(name, [:set, :named_table, read_concurrency: true, keypos: 1])
  end

  defp insert(ds, key, item) do
    :ets.insert(ds, {key, item})
  end

  defp lookup(ds, key) do
    case exists?(ds, key) do
      true ->
        :ets.lookup_element(ds, key, 2)
      false ->
        nil
    end
  end

  defp get_all(ds) do
    :ets.tab2list(ds)
    |> Enum.map(fn {_, metric} -> metric end)
  end

  defp delete_all(ds) do
    :ets.delete_all_objects(ds)
  end

  defp exists?(ds, key) do
    :ets.member(ds, key)
  end

end
