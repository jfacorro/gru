defmodule Grog.Metrics.Server do
  use GenServer
  require Logger
  alias Grog.Metrics.Metric

  @datastore __MODULE__

  ## API

  def report(metric, value) do
    name = Metric.name(metric)
    metrics = lookup(@datastore, name) || %{}

    metric_type = metric.__struct__
    metric = Map.get(metrics, metric_type, metric)
    metric = Metric.accumulate(metric, value)

    metrics = Map.put(metrics, metric_type, metric)
    insert(@datastore, name, metrics)
  end

  def get(name) do
    lookup(@datastore, name)
  end

  def get_all do
    get_all(@datastore)
  end

  def clear do
    delete_all(@datastore)
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

  def terminate(_reason, _state) do
    Logger.info("Terminating '#{inspect __MODULE__}'")
  end

  ## Internal

  defp create_table(name) do
    opts = [:set,
            :named_table,
            :public,
            read_concurrency: true,
            write_concurrency: true,
            keypos: 1]
    :ets.new(name, opts)
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
