ExUnit.start()

defmodule GrogTest.Client do
  use Grog.Client, name: "Test", min_wait: 500, max_wait: 1000
  alias Grog.Metric.Server
  alias Grog.Metric.Count
  require Logger

  @weight 100
  deftask get_status(data) do
    Server.report(%Count{name: "Test"}, 1)
    data
  end
end
