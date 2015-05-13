 defmodule Grog.Client.Dummy do
  use Grog.Client, name: "Dummy", min_wait: 100, max_wait: 2000
  require Logger

  @host "http://localhost"

  @weight 20
  deftask get_status(client) do
    Logger.info "#{client.name} getting status..."
    Grog.HTTP.get(@host <> "/status", %{}, name: "Status")
  end

  @weight 2
  deftask get_contents(client) do
    Logger.info "#{client.name} getting contents..."
  end

  @weight 10
  deftask get_featured(client) do
    Logger.info "#{client.name} getting featured..."
  end
end
