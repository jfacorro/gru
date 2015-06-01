defmodule Grog.Web do
  alias Plug.Adapters.Cowboy

  def start(clients, port, root) do
    opts = [clients: clients, root: root]
    Cowboy.http Grog.Web.Router, opts, port: port
  end

  def stop do
    Cowboy.shutdown Grog.Web.Router.HTTP
  end
end
