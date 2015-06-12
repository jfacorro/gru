defmodule GrogTest do
  use ExUnit.Case

  test "Start 100 clients in 1 second" do
    Grog.start(GrogTest.Client, 100, 100)
    :timer.sleep(1000)
    assert(Grog.status.count == 100)
    Grog.stop
  end

  test "Start 100 clients in 2 second" do
    Grog.start(GrogTest.Client, 100, 50)
    :timer.sleep(1000)
    assert(Grog.status.count != 100)
    :timer.sleep(1000)
    assert(Grog.status.count == 100)
    Grog.stop
  end

  test "Start 100 clients in 0.5 second" do
    Grog.start(GrogTest.Client, 100, 200)
    :timer.sleep(500)
    assert(Grog.status.count == 100)
    Grog.stop
  end

  test "Start clients check status, then clear" do
    Grog.start(GrogTest.Client, 100, 1000)
    :timer.sleep(500)
    assert(Grog.status.count == 100)
    assert(length(Grog.status.metrics) != 0)
    Grog.stop
    assert(length(Grog.status.metrics) != 0)
    Grog.clear
    assert(length(Grog.status.metrics) == 0)
  end
end
