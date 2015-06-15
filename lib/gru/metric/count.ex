defmodule Gru.Metric.Count do
  alias Gru.Metric.Count
  defstruct id: :count, description: "", count: 0

  defimpl Gru.Metric, for: Count do
    def id(metric), do: metric.id

    def value(metric), do: metric.count

    def accumulate(metric, value) do
      %{metric | count: metric.count + value}
    end
  end
end
