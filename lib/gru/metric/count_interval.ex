defmodule Gru.Metric.CountInterval do
  alias Gru.Metric.CountInterval
  defstruct id: :count_interval, description: "", interval: 1000,
            last_now: :erlang.now(), last_count: 0,
            current_count: 0

  defimpl Gru.Metric.Protocol, for: CountInterval do
    def id(metric), do: metric.id

    def value(metric), do: metric.last_count

    def accumulate(metric, value) do
      now = :erlang.now
      diff_ms = :timer.now_diff(now, metric.last_now) / 1000
      case diff_ms < metric.interval do
        true ->
          %{metric | current_count: metric.current_count + value}
        false ->
          %{metric |
            current_count: value,
            last_now: now,
            last_count: metric.current_count * metric.interval / diff_ms}
      end
    end
  end
end
