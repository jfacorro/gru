defmodule Grog.Web.Router do
  use Plug.Router
  import Grog.Web.Utils
  plug :match
  plug :dispatch

  @root System.get_env("HOME") <> "/.grog"

  static "/", @root, "/index.html"
  static "/index.html", @root, "/index.html"
  static "/js/*_", @root
  static "/css/*_", @root
  static "/img/*_", @root

  get "/api/status" do
    send_resp(conn, 200, "{}")
  end

  post "/api/start" do
    send_resp(conn, 200, "{'status':'started'}")
  end

  match _ do
    send_resp(conn, 404, "Oops")
  end
end
