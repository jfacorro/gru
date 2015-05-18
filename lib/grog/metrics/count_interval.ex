defmodule Grog.Metrics.CountInterval do
  alias Grog.Metrics.CountInterval
  defstruct name: "", interval: 1000,
            last_now: :erlang.now(), last_count: 0,
            current_count: 0

  defimpl Grog.Metrics.Metric, for: CountInterval do
    def name(metric), do: metric.name

    def value(metric), do: metric.last_count

    def accumulate(metric, value) do
      now = :erlang.now
      diff_ms = :timer.now_diff(now, metric.last_now) / 1000
      case diff_ms < 1000 do
        true ->
          %{metric | current_count: metric.current_count + value}
        false ->
          %{metric |
            current_count: value,
            last_now: now,
            last_count: metric.current_count * 1000 / diff_ms}
      end
    end
  end
end
