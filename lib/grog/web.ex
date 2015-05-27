defmodule Grog.Web do
  alias Plug.Adapters.Cowboy

  def start(port) do
    Cowboy.http Grog.Web.Router, [], port: port
  end

  def stop do
    Cowboy.shutdown Grog.Web.Router.HTTP
  end
end
