defmodule Grog.Metric.Server do
  use GenServer
  alias Grog.Metric

  @datastore __MODULE__

  ## API

  @spec report(any, Metric.t, any) :: :ok
  def report(key, metric, value) do
    metrics = lookup(@datastore, key) || %{}
    id = Metric.id(metric)
    metrics = update_in(metrics, [id],
                        &Metric.accumulate(&1 || metric, value))
    insert(@datastore, key, metrics)
    :ok
  end

  def get(key) do
    lookup(@datastore, key)
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
    create_table(@datastore)
    {:ok, {}}
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
    |> :maps.from_list
  end

  defp delete_all(ds) do
    :ets.delete_all_objects(ds)
  end

  defp exists?(ds, key) do
    :ets.member(ds, key)
  end

end
