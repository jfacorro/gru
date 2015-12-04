defmodule Gru.Metric.Server do
  use GenServer
  alias Gru.Utils
  alias Gru.Metric.Protocol, as: Proto

  @index Gru.Metric.Index
  @metrics [Gru.Metric.Average,
            Gru.Metric.Count,
            Gru.Metric.CountInterval,
            Gru.Metric.Min,
            Gru.Metric.Max,
            Gru.Metric.Percentiles]

  ## API

  @spec notify(any, Metric.t, any) :: :ok
  def notify(group, metric, value) do
    key = {group, metric}
    case lookup(@index, key) do
      nil ->
        {:ok, pid} = Supervisor.start_child(Gru.Metric.Supervisor, [metric, value])
        :ets.insert(@index, {key, pid})
      pid ->
        Gru.Metric.Worker.update(pid, value)
    end
  end

  def get_all do
    GenServer.call(__MODULE__, :all)
  end

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  ## GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    create_table(@index)
    Enum.map(@metrics, &create_metric_table/1)
    {:ok, %{}}
  end

  def handle_call(:all, _from, state) do
    all = :ets.tab2list(@index)
    |> Enum.map(&get_metric/1)
    |> Enum.reduce(%{}, &build_all/2)

    {:reply, all, state}
  end

  def handle_call(:clear, _from, state) do
    Enum.map(@metrics, &:ets.delete_all_objects/1)

    {:reply, :ok, state}
  end

  ## Internal

  defp build_all(nil, result) do
    result
  end
  defp build_all({group, metric}, result) do
    result = update_in(result, [group], &(&1 || %{}))
    id = Proto.id(metric)
    put_in(result, [group, id], metric)
  end

  defp get_metric({{group, metric}, pid}) do
    try do
      table = Utils.struct_type(metric)
      metric = :ets.lookup_element(table, pid, 2)
      {group, metric}
    catch
      _, :badarg -> nil
    end
  end

  defp create_table(name) do
    opts = [:set,
            :named_table,
            :public,
            read_concurrency: false,
            write_concurrency: true,
            keypos: 1]
    :ets.new(name, opts)
  end

  defp create_metric_table(name) do
    opts = [:set,
            :named_table,
            :public,
            read_concurrency: true,
            write_concurrency: false,
            keypos: 1]
    :ets.new(name, opts)
  end

  defp lookup(table, key) do
    case :ets.member(table, key) do
      true  -> :ets.lookup_element(table, key, 2)
      false -> nil
    end
  end
end
