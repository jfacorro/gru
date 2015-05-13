defmodule Grog.Metrics.Count do
  alias Grog.Metrics.Count
  defstruct name: "", count: 0

  defimpl Grog.Metrics.Metric, for: Grog.Metrics.Count do
    def name(metric), do: metric.name
    def value(metric), do: metric.count
    def accumulate(metric, value) do
      %{metric | count: metric.count+ 1}
    end
  end
end
