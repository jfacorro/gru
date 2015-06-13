defmodule Grog.WebTest do
  use ExUnit.Case
  alias Grog.HTTP

  setup_all do
    Grog.Web.start [GrogTest.Client], 8080, "web"
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
    assert is_map(metrics)
    assert status == :stopped

    HTTP.close(conn)
  end

  test "POST /api/clients, DELETE /api/clients" do
    conn = HTTP.open("localhost", 8080)
    data = %{count: 10, rate: 10}
    req_body = Eden.encode!(data)

    {:ok, %{status_code: 200, body: body}} =
      HTTP.post(conn, "/api/clients", req_body, %{}, %{report: false})
    assert %{result: :ok} = Eden.decode!(body)

    {:ok, %{body: body}} =
      HTTP.get(conn, "/api/status", %{}, %{report: false})
    %{status: :running,
      metrics: metrics} = Eden.decode!(body)

    :timer.sleep(1000)
    assert Map.keys(metrics) == [%{name: "Test", method: "GET"}]

    {:ok, %{status_code: 204}} =
      HTTP.delete(conn, "/api/clients", "", %{}, %{report: false})
    {:ok, %{body: body}} =
      HTTP.get(conn, "/api/status", %{}, %{report: false})
    %{status: :stopped} = Eden.decode!(body)

    HTTP.close(conn)
  end
end
