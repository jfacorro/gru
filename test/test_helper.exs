# ExUnit.start()

defmodule GrogTest.Client.Tasks do
  use Grog.Client.Tasks
  alias Grog.Metric.Server
  alias Grog.Metric.Count

  @weight 100
  deftask get_status(data) do
    Server.report(%Count{name: "Test"}, 1)
    data
  end
end

defmodule GrogTest.Client do
  use Grog.Client, name: "Test Client",
  min_wait: 500, max_wait: 1000, weight: 10,
  tasks_module: GrogTest.Client.Tasks
end

defmodule GrogTest.Client2 do
  use Grog.Client, name: "Test Client 2",
  min_wait: 500, max_wait: 1000, weight: 5,
  tasks_module: GrogTest.Client.Tasks
end
