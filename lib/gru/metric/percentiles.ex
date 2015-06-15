defmodule Gru.Metric.Percentiles do
  alias Gru.Metric.Percentiles
  alias Gru.HdrHistogram
  defstruct id: :percentiles, description: "",
            hist: HdrHistogram.new(1, 3600000000, 1)

  defimpl Gru.Metric, for: Percentiles do
    @percentiles [50, 66, 75, 80, 90, 95, 98, 99, 100]

    def id(metric), do: metric.id

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
