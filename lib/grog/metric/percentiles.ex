defmodule Grog.Metric.Percentiles do
  alias Grog.Metric.Percentiles
  alias Grog.HdrHistogram
  defstruct name: "", hist: HdrHistogram.new(1, 3600000000, 1)

  @percentiles [50, 66, 75, 80, 90, 95, 98, 99, 100]

  defimpl Grog.Metric, for: Percentiles do
    def name(metric), do: metric.name

    def value(metric) do
      @percentiles
      |> Enum.map(fn p -> {p, HdrHistogram.percentile(metric.hist, p)} end)
      |> Enum.into(%{})
    end

    def accumulate(metric, value) do
      %{metric
        | hist: HdrHistogram.record(metric.hist, value)}
    end
  end
end
