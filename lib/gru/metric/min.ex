defmodule Gru.Metric.Min do
  alias Gru.Metric.Min
  defstruct id: :min, description: "", min: nil

  defimpl Gru.Metric.Protocol, for: Min do
    def id(metric), do: metric.id

    def value(metric), do: metric.min

    def accumulate(metric, value) do
      %{metric | min: min(metric.min || value, value)}
    end
  end
end
