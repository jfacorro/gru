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
    send_resp(conn, 200, ExEdn.encode!(Grog.status))
  end

  ## POST /api/clients
  ## The body of the request should be a map with two keys:
  ##  - :count - the total amount of clients to start.
  ##  - :rate - the rate per second at which clients should be started.
  post "/api/clients" do
    clients = Map.get(conn.private, :clients)
    {:ok, body, conn} = read_body(conn)
    IO.inspect(body)
    %{count: count, rate: rate} = ExEdn.decode!(body)

    result = Grog.start clients, count, rate
    send_resp(conn, 200, ExEdn.encode!(%{result: result}))
  end

  delete "/api/clients" do
    Grog.stop
    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "Oops")
  end
end
