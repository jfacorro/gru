defmodule Gru.Metric.Server do
  use GenServer
  alias Gru.Metric

  @table :metric

  ## API

  @spec report(any, Metric.t, any) :: :ok
  def report(name, metric, value) do
    fun = fn() ->
      id = Metric.id(metric)
      key = {name, id}
      metric = (lookup(@table, key, :write) || metric)
               |> Metric.accumulate(value)
      insert(@table, key, metric)
    end
    transaction(fun)
  end

  def get_all do
    get_all(@table)
  end

  def clear do
    delete_all(@table)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    create_table(@table)
    {:ok, {}}
  end

  ## Internal

  defp create_table(table) do
    Application.start(:mnesia)
    table_config = [ram_copies: [node()],
                    type: :set,
                    attributes: [:key, :metric],
                    storage_properties: [ets: [write_concurrency: true]]]
    :mnesia.create_table(table, table_config)

    :mnesia.wait_for_tables([table], 5000)
  end

  defp insert(table, key, item) do
    :mnesia.write({table, key, item})
  end

  defp transaction(fun) do
    {:atomic, result} = :mnesia.transaction(fun)
    result
  end

  defp lookup(table, key, lock_kind) do
    case :mnesia.read(table, key, lock_kind) do
      [] -> nil
      [{^table, _, metrics}] -> metrics
    end
  end

  defp get_all(table) do
    table
    |> :mnesia.dirty_all_keys
    |> Enum.map(&:mnesia.dirty_read({table, &1}))
    |> Enum.reduce(%{},
      fn([{_, {name, id}, metric}], result) ->
        result = update_in(result, [name], &(&1 || %{}))
        put_in(result, [name, id], metric)
      end)
  end

  defp delete_all(table) do
    fun = fn() ->
      keys = :mnesia.all_keys(table)
      Enum.each keys, &:mnesia.delete({table, &1})
    end
    transaction(fun)
  end

end
