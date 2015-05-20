defmodule Grog.Metric.Min do
  alias Grog.Metric.Min
  defstruct name: "", min: nil

  defimpl Grog.Metric, for: Min do
    def name(metric), do: metric.name

    def value(metric), do: metric.min

    def accumulate(metric, value) do
      %{metric | min: min(metric.min || value, value)}
    end
  end
end
