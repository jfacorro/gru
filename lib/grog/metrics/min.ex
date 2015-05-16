defmodule Grog.Metrics.Min do
  alias Grog.Metrics.Min
  defstruct name: "", min: nil

  defimpl Grog.Metrics.Metric, for: Min do
    def name(metric), do: metric.name

    def value(metric), do: metric.min

    def accumulate(metric, value) do
      %{metric | min: min(metric.min || value, value)}
    end
  end
end
