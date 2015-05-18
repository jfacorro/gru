 defmodule Grog.Client.Dummy do
  use Grog.Client, name: "Dummy", min_wait: 5000, max_wait: 10000,
                   conn: Grog.HTTP.open("localhost", 8383)
  require Logger

  @weight 20
  deftask get_status(data) do
    Grog.HTTP.get(data.conn, "/status", %{}, %{name: "Status"})
    data
  end

  @weight 2
  deftask get_contents(data) do
    Grog.HTTP.get(data.conn, "/status", %{}, %{name: "Status"})
    data
  end

  @weight 10
  deftask get_featured(data) do
    Grog.HTTP.get(data.conn, "/status", %{}, %{name: "Status"})
    data
  end

  def terminate(data) do
    Grog.HTTP.close(data.conn)
  end
end
