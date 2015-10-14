defmodule Examples.Noop.Tasks do
  use Gru.Minion.Tasks

  @weight 100
  deftask get_status(data) do
    Gru.HTTP.get(data.conn, "/")
    data
  end
end

defmodule Examples.Noop.Minion do
  use Gru.Minion, name: "Examples Noop Minion",
  min_wait: 1000, max_wait: 5000, weight: 5,
  tasks_module: Examples.Noop.Tasks

  def init(data) do
    conn = Gru.HTTP.open("localhost", 8181)
    Map.put(data, :conn, conn)
  end
end
