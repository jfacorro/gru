defmodule Gru.Metric.Max do
  alias Gru.Metric.Max
  defstruct id: :max, description: "", max: nil

  defimpl Gru.Metric.Protocol, for: Max do
    def id(metric), do: metric.id

    def value(metric), do: metric.max

    def accumulate(metric, value) do
      %{metric | max: max(metric.max || value, value)}
    end
  end
end
