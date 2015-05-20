defmodule Grog.Metric.Count do
  alias Grog.Metric.Count
  defstruct name: "", count: 0

  defimpl Grog.Metric, for: Count do
    def name(metric), do: metric.name

    def value(metric), do: metric.count

    def accumulate(metric, value) do
      %{metric | count: metric.count + value}
    end
  end
end
