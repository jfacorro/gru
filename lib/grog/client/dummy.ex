 defmodule Grog.Client.Dummy do
  use Grog.Client, name: "Dummy", min_wait: 1000, max_wait: 2000
  require Logger

  @host "http://localhost:8383"

  @weight 20
  deftask get_status(_client) do
    Grog.HTTP.get(@host <> "/status", %{}, name: "Status")
  end

  @weight 2
  deftask get_contents(_client) do
    Grog.HTTP.get(@host <> "/status", %{}, name: "Status")
  end

  @weight 10
  deftask get_featured(_client) do
    Grog.HTTP.get(@host <> "/status", %{}, name: "Status")
  end
end
