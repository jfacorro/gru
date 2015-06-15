defmodule Gru.UtilsTest do
  use ExUnit.Case
  alias Gru.Utils
  require Gru.Utils

  test "repeat/1" do
    stream = Utils.repeat(1)
    assert Enum.take(stream, 5) == [1, 1, 1, 1, 1]
    stream = Utils.repeat(:a)
    assert Enum.take(stream, 10) == [:a, :a, :a, :a, :a, :a, :a, :a, :a, :a]
  end

  test "repeat/2" do
    stream = Utils.repeat(:hello, 0)
    assert Enum.take(stream, 5) == []
    stream = Utils.repeat("Hi!", 2)
    assert Enum.take(stream, 5) == ["Hi!", "Hi!"]
    assert Enum.take(stream, 42) == ["Hi!", "Hi!"]

    assert_raise FunctionClauseError, fn -> Utils.repeat(:boom!, -1) end
  end

  test "time/1" do
    {time, :ok} = Utils.time(:timer.sleep(1000))
    assert(1.0e6 < time and time < 1.5e6)
  end

  test "uniform/1" do
    stream = Stream.repeatedly(fn -> Utils.uniform(1000) end)
    nums = Enum.take(stream, 1000)
    assert Enum.all?(nums, fn x -> 0 <= x and x < 1000 end)
  end

  test "uniform/2" do
    low = 100
    high = 1000
    stream = Stream.repeatedly(fn -> Utils.uniform(low, high) end)
    nums = Enum.take(stream, 1000)
    assert Enum.all?(nums, fn x -> low <= x and x < high end)
  end

  test "ceil/1" do
    assert(Utils.ceil(1.5) == 2)
    assert(Utils.ceil(1.1) == 2)
    assert(Utils.ceil(1.0) == 1)

    assert(Utils.ceil(10.9) == 11)
    assert(Utils.ceil(10.999) == 11)
    assert(Utils.ceil(9.999) == 10)

    assert(Utils.ceil(-9.999) == -9)
    assert(Utils.ceil(-1.0) == -1)
  end

  test "leading_zeros/1" do
    assert(Utils.leading_zeros(100) == 57)
    assert(Utils.leading_zeros(146754387) == 36)
    assert(Utils.leading_zeros(58) == 58)
    assert(Utils.leading_zeros(243049343908) == 26)
    assert(Utils.leading_zeros(2430493439083232323) == 2)
  end
end
