defmodule Examples.Status.Tasks do
  use Gru.Minion.Tasks
  alias Gru.Metric.Server
  alias Gru.Metric.Count
  alias Gru.Metric.CountInterval

  @weight 100
  deftask get_status(data) do
    if data[:conn] do
      Gru.HTTP.get(data.conn, "/api/status")
    else
      key = %{name: "Test", type: "GET"}
      Server.report(key, %Count{id: :num_reqs}, 1)
      Server.report(key, %CountInterval{id: :reqs_sec}, 1)
    end
    data
  end
end

defmodule Examples.Minion.Status do
  use Gru.Minion, name: "Examples Status Minion",
  min_wait: 1000, max_wait: 5000, weight: 5,
  tasks_module: Examples.Status.Tasks

  def init(data) do
    Map.put(data, :conn, Gru.HTTP.open("localhost", 8888))
  end
end
