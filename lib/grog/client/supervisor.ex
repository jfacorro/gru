defmodule Grog.Client.Supervisor do
  use Supervisor

  ## Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [worker(Grog.Client, [], shutdown: 5000)]
    supervise(children, strategy: :simple_one_for_one)
  end

  ## API

  def count do
    Supervisor.count_children(__MODULE__)
  end

  def children do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def start_child client do
    Supervisor.start_child(__MODULE__, [client])
  end

  def stop_child pid do
    Supervisor.terminate_child(__MODULE__, pid)
  end
end
