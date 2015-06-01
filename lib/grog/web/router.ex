defmodule Grog.Web.Router do
  use Plug.Router
  import Grog.Web.Utils
  plug :match
  plug :dispatch

  @root System.get_env("HOME") <> "/.grog"

  def call(conn, opts) do
    conn
    |> put_private(:root, opts[:root] || @root)
    |> put_private(:clients, opts[:clients])
    |> super(opts)
  end

  static "/", "/index.html"
  static "/index.html", "/index.html"
  static "/js/*_"
  static "/css/*_"
  static "/img/*_"

  get "/api/status" do
    send_resp(conn, 200, "{}")
  end

  post "/api/start" do
    clients = Map.get(conn.private, :clients)
    Grog.start clients, 1000, 10
    send_resp(conn, 200, "{'status':'started'}")
  end

  match _ do
    send_resp(conn, 404, "Oops")
  end
end
