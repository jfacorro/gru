defmodule Gru.Web.Router do
  use Plug.Router
  import Gru.Web.Utils
  alias Gru.Metric
  plug :match
  plug :dispatch

  @root System.get_env("HOME") <> "/.gru"

  def call(conn, opts) do
    conn
    |> put_private(:root, opts[:root] || @root)
    |> put_private(:minions, opts[:minions])
    |> super(opts)
  end

  static "/", "/index.html"
  static "/index.html", "/index.html"
  static "/js/*_"
  static "/css/*_"
  static "/img/*_"

  get "/api/status" do
    status = Gru.status
    |> merge_metrics
    |> discriminate_total

    send_resp(conn, 200, Eden.encode!(status))
  end

  defp merge_metrics(%{metrics: metrics} = status) do
    metrics = for {key, metrics_local} <- metrics, into: [] do
      for {id, metric} <- metrics_local, into: key do
        {id, Metric.value(metric)}
      end
    end
    %{status | metrics: metrics}
  end

  defp discriminate_total(%{metrics: metrics} = status) do
    case Enum.partition(metrics, &total?/1) do
      {[], _metrics} ->
        status
      {[total], metrics} ->
        Map.merge(status, %{metrics: metrics, total: total})
    end
  end

  defp total?(metric), do: metric[:name] == "Total"

  ## POST /api/minions
  ## The body of the request should be a map with two keys:
  ##  - :count - the total amount of minions to start.
  ##  - :rate - the rate per second at which minions should be started.
  post "/api/minions" do
    minions = Map.get(conn.private, :minions)
    {:ok, body, conn} = read_body(conn)
    %{count: count, rate: rate} = Eden.decode!(body)

    {status_code, body} =
      case Gru.start(minions, count, rate) do
        :ok ->
          {200, Eden.encode!(%{result: :ok})}
        {:error, reason} ->
          {400, Eden.encode!(%{result: reason})}
      end

    send_resp(conn, status_code, body)
  end

  delete "/api/minions" do
    Gru.stop
    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "Oops")
  end
end
