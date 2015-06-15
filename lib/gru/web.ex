defmodule Gru.Web do
  alias Plug.Adapters.Cowboy

  def start(minions, port, root) do
    opts = [minions: minions, root: root]
    Cowboy.http Gru.Web.Router, opts, port: port
  end

  def stop do
    Cowboy.shutdown Gru.Web.Router.HTTP
  end
end
