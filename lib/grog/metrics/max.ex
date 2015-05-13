defmodule Grog.Metrics.Max do
  alias Grog.Metrics.Max
  defstruct name: "", max: nil

  defimpl Grog.Metrics.Metric, for: Max do
    def name(metric), do: metric.name

    def value(metric), do: metric.max

    def accumulate(metric, value) do
      %{metric | max: max(metric.max || value, value)}
    end
  end
end
