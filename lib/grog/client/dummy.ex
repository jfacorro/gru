 defmodule Grog.Client.Dummy do
  use Grog.Client, name: "Dummy", min_wait: 100, max_wait: 2000
  require Logger

  deftask get_status(client) do
    Logger.info "#{client.name} getting status..."
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
