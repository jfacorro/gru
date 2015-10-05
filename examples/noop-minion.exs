defmodule Examples.Status.Tasks do
  use Gru.Minion.Tasks

  @weight 100
  deftask get_status(data) do
    Gru.HTTP.get(data.conn, "/api/noop")
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
