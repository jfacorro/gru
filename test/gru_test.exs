defmodule GruTest do
  use ExUnit.Case
  alias GruTest.Utils

  test "Start 100 minions in 1 second" do
    Utils.wait_for(&stopped?/0)

    Gru.start(GruTest.Minion, 100, 100)
    :timer.sleep(1000)
    assert(Gru.status.count == 100)
    Gru.stop
  end

  test "Start 100 minions in 2 second" do
    Utils.wait_for(&stopped?/0)

    Gru.start(GruTest.Minion, 100, 50)
    :timer.sleep(800)
    assert(Gru.status.count != 100)
    :timer.sleep(1500)
    assert(Gru.status.count == 100)
    Gru.stop
  end

  test "Start 100 minions in 0.5 second" do
    Utils.wait_for(&stopped?/0)
    try do
      Gru.start(GruTest.Minion, 100, 200)
      :timer.sleep(1000)
      assert(Gru.status.count == 100)
    after
      Gru.stop
    end
  end

  test "Start minions check status, then clear" do
    Utils.wait_for(&stopped?/0)
    try do
      Gru.start(GruTest.Minion, 100, 1000)
      :timer.sleep(1000)
      assert(Gru.status.count == 100)
      assert(Map.keys(Gru.status.metrics) != [])
    after
      Gru.stop
      assert(Map.keys(Gru.status.metrics) != [])
      Gru.clear
      assert(Map.keys(Gru.status.metrics) == [])
    end
  end

  defp stopped? do
    Gru.status.status == :stopped
  end
end
