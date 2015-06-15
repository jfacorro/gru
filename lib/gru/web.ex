defmodule Gru.Web do
  alias Plug.Adapters.Cowboy

  def start(clients, port, root) do
    opts = [clients: clients, root: root]
    Cowboy.http Gru.Web.Router, opts, port: port
  end

  def stop do
    Cowboy.shutdown Gru.Web.Router.HTTP
  end
end
