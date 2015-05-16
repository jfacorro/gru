 defmodule Grog.Client.Dummy do
  use Grog.Client, name: "Dummy", min_wait: 1000, max_wait: 2000,
                   conn: Grog.HTTP.open("localhost", 8383)
  require Logger

  @weight 20
  deftask get_status(state) do
    Grog.HTTP.get(state.conn, "/status", %{}, %{name: "Status"})
    state
  end

  @weight 2
  deftask get_contents(state) do
    Grog.HTTP.get(state.conn, "/status", %{}, %{name: "Status"})
    state
  end

  @weight 10
  deftask get_featured(state) do
    Grog.HTTP.get(state.conn, "/status", %{}, %{name: "Status"})
    state
  end

  def terminate(state) do
    Grog.HTTP.close(state.conn)
  end

end
