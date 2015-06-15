defmodule Grog.WebTest do
  use ExUnit.Case
  alias Grog.HTTP

  setup_all do
    Grog.Web.start [GrogTest.ClientWeb], 8080, "web"
    Grog.clear
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

  test "POST /api/clients, DELETE /api/clients" do
    conn = HTTP.open("localhost", 8080)
    data = %{count: 10, rate: 10}
    req_body = Eden.encode!(data)

    try do
      {:ok, %{status_code: 200, body: body}} =
        HTTP.post(conn, "/api/clients", req_body, %{}, %{report: false})
      assert %{result: :ok} = Eden.decode!(body)

      :timer.sleep(500)
      {:ok, %{body: body}} =
        HTTP.get(conn, "/api/status", %{}, %{report: false})
      %{status: :running,
        metrics: metrics} = Eden.decode!(body)

      assert length(metrics) == 2
    after
      {:ok, %{status_code: 204}} =
        HTTP.delete(conn, "/api/clients", "", %{}, %{report: false})
      {:ok, %{body: body}} =
        HTTP.get(conn, "/api/status", %{}, %{report: false})
      %{status: :stopping} = Eden.decode!(body)

      HTTP.close(conn)
    end
  end
end
