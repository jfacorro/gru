defmodule Grog.WebTest do
  use ExUnit.Case
  alias Grog.HTTP

  setup_all do
    Grog.Web.start [GrogTest.Client], 8080, "web"
    :ok
  end

  test "Index" do
    conn = HTTP.open("localhost", 8080)

    {:ok, %{status_code: 200,
            body: body1}} = HTTP.get(conn, "/index.html", %{}, %{report: false})
    {:ok, %{status_code: 200,
            body: body2}} = HTTP.get(conn, "/", %{}, %{report: false})

    assert body1 == body2
  end
end
