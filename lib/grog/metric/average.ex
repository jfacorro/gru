defmodule Grog.Metric.Average do
  alias Grog.Metric.Average
  defstruct name: "", count: 0, sum: 0

  defimpl Grog.Metric, for: Average do
    def name(metric), do: metric.name

    def value(%Average{count: 0}), do: 0
    def value(metric), do: metric.sum / metric.count

    def accumulate(metric, value) do
      %{metric
        | count: metric.count + 1,
          sum: metric.sum + value}
    end
  end
end
