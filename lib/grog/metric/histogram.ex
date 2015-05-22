defmodule Grog.Metric.Histogram do
  defstruct name: "", histogram: Grog.HdrHistogram.new(1, 3600000, 1)
end

defimpl Grog.Metric, for: Grog.Metric.Histogram do
  def name(metric), do: metric.name

  def value(metric), do: metric.histogram

  def accumulate(metric, value) do
    %{metric
      | histogram: Grog.HdrHistogram.report(metric.histogram, value)}
  end
end
