defmodule Grog.Client.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [worker(Grog.Client.Server, [])]
    supervise(children, strategy: :simple_one_for_one)
  end

  def clients_count do
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
