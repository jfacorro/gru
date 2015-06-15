defmodule GrogTest do
  use ExUnit.Case
  alias GrogTest.Utils

  test "Start 100 clients in 1 second" do
    Utils.wait_for(&stopped?/0)

    Grog.start(GrogTest.Client, 100, 100)
    :timer.sleep(1000)
    assert(Grog.status.count == 100)
    Grog.stop
  end

  test "Start 100 clients in 2 second" do
    Utils.wait_for(&stopped?/0)

    Grog.start(GrogTest.Client, 100, 50)
    :timer.sleep(1000)
    assert(Grog.status.count != 100)
    :timer.sleep(1000)
    assert(Grog.status.count == 100)
    Grog.stop
  end

  test "Start 100 clients in 0.5 second" do
    Utils.wait_for(&stopped?/0)
    try do
      Grog.start(GrogTest.Client, 100, 200)
      :timer.sleep(1000)
      assert(Grog.status.count == 100)
    after
      Grog.stop
    end
  end

  test "Start clients check status, then clear" do
    Utils.wait_for(&stopped?/0)
    try do
      Grog.start(GrogTest.Client, 100, 1000)
      :timer.sleep(1000)
      assert(Grog.status.count == 100)
      assert(Map.keys(Grog.status.metrics) != [])
    after
      Grog.stop
      assert(Map.keys(Grog.status.metrics) != [])
      Grog.clear
      assert(Map.keys(Grog.status.metrics) == [])
    end
  end

  defp stopped? do
    Grog.status.status == :stopped
  end
end
