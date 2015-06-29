defmodule Gru.WebTest do
  use ExUnit.Case
  alias Gru.HTTP

  setup_all do
    Gru.Web.start [GruTest.MinionWeb], 8080, "web"
    Gru.clear
    :ok
  end

  test "GET /; GET /index.html" do
    conn = HTTP.open("localhost", 8080)

    {:ok, %{status_code: 200,
            body: body1}} = HTTP.get(conn, "/index.html",
                                     %{}, %{report: false})
    {:ok, %{status_code: 200,
            body: body2}} = HTTP.get(conn, "/", %{},
                                     %{report: false})
    assert body1 == body2

    HTTP.close(conn)
  end

  test "GET /api/status" do
    conn = HTTP.open("localhost", 8080)

    {:ok, %{status_code: 200,
            body: body}} = HTTP.get(conn, "/api/status",
                                    %{}, %{report: false})
    %{count: count,
      metrics: metrics,
      status: status} = Eden.decode!(body)
    assert is_integer(count)
    assert is_list(metrics)
    assert status == :stopped || status == :stopping

    HTTP.close(conn)
  end

  test "DELETE /api/status" do
    conn = HTTP.open("localhost", 8080)

    {:ok, %{status_code: 204}} = HTTP.delete(conn, "/api/status", "",
                                             %{}, %{report: false})

    HTTP.close(conn)
  end

  test "POST /api/minions, DELETE /api/minions" do
    conn = HTTP.open("localhost", 8080)
    data = %{count: 10, rate: 10}
    req_body = Eden.encode!(data)

    try do
      {:ok, %{status_code: 200, body: body}} =
        HTTP.post(conn, "/api/minions", req_body, %{}, %{report: false})
      assert %{result: :ok} = Eden.decode!(body)

      :timer.sleep(500)
      {:ok, %{body: body}} =
        HTTP.get(conn, "/api/status", %{}, %{report: false})
      %{status: :starting,
        metrics: metrics,
        total: total} = Eden.decode!(body)

      assert length(metrics) == 1
      assert length(Map.keys(total)) != 0
    after
      {:ok, %{status_code: 204}} =
        HTTP.delete(conn, "/api/minions", "", %{}, %{report: false})
      {:ok, %{body: body}} =
        HTTP.get(conn, "/api/status", %{}, %{report: false})
      %{status: :stopping} = Eden.decode!(body)

      HTTP.close(conn)
    end
  end
end
