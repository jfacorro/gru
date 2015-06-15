defmodule Grog.Web.Router do
  use Plug.Router
  import Grog.Web.Utils
  alias Grog.Metric
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
    status = %{metrics: metrics} = Grog.status
    metrics = for {key, metrics_local} <- metrics, into: [] do
      for {id, metric} <- metrics_local, into: key do
        {id, Metric.value(metric)}
      end
    end
    status = %{status | metrics: metrics}
    send_resp(conn, 200, Eden.encode!(status))
  end

  ## POST /api/clients
  ## The body of the request should be a map with two keys:
  ##  - :count - the total amount of clients to start.
  ##  - :rate - the rate per second at which clients should be started.
  post "/api/clients" do
    clients = Map.get(conn.private, :clients)
    {:ok, body, conn} = read_body(conn)
    %{count: count, rate: rate} = Eden.decode!(body)

    {status_code, body} =
      case Grog.start(clients, count, rate) do
        :ok ->
          {200, Eden.encode!(%{result: :ok})}
        {:error, reason} ->
          {400, Eden.encode!(%{result: reason})}
      end

    send_resp(conn, status_code, body)
  end

  delete "/api/clients" do
    Grog.stop
    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "Oops")
  end
end
