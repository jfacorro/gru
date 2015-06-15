ExUnit.start(max_cases: 1)
Logger.configure(level: :error)

defmodule GruTest.Utils do
  def wait_for(fun, timeout \\ 5000) do
    do_wait_for(fun, timeout, :os.timestamp)
  end

  defp do_wait_for(fun, timeout, then) do
    diff = :timer.now_diff(:os.timestamp, then) / 1000
    if timeout > diff && not fun.() do
      :timer.sleep(trunc(timeout / 10))
      do_wait_for(fun, timeout, then)
    end
  end
end

defmodule GruTest.Client.Tasks do
  use Gru.Client.Tasks
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

defmodule GruTest.Client do
  use Gru.Client, name: "Test Client",
  min_wait: 500, max_wait: 1000, weight: 10,
  tasks_module: GruTest.Client.Tasks
end

defmodule GruTest.ClientWeb do
  use Gru.Client, name: "Test Web Client",
  min_wait: 0, max_wait: 1, weight: 5,
  tasks_module: GruTest.Client.Tasks

  def init(data) do
    Map.put(data, :conn, Gru.HTTP.open("localhost", 8080))
  end
end
