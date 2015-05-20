defmodule Grog.Metric.Histogram do
  alias Grog.Metric.Histogram
  import Grog.Utils

  defstruct lowest: nil, highest: nil, digits: nil,
  bucket_count: nil,
  sub_bucket_count: nil, sub_bucket_half_count: nil,
  sub_bucket_mask: nil, sub_bucket_half_count_magnitude: nil,
  unit_magnitude: nil,
  counts_length: nil,
  leading_zero_count: nil,
  counts: nil, min: nil, max: nil,
  total_count: 0

  @max_value 1.8446744073709552e19

  def new(lowest, highest, digits \\ 3) do
    assert(lowest >= 1, "lowest (discernible value) must be >= 1")
    assert(highest >= 2 * lowest,
              "highest (trackable value) must be >= 2 * lowest (discernible value)")
    assert(digits >= 0 and digits <= 5,
              "(number of significant) digits must be between 0 and 5")

    hist = %Histogram{highest: highest, lowest: lowest, digits: digits}
    init(hist)
  end

  def record(hist, value) do
    index = counts_index(hist, value)
    IO.puts "index #{inspect index}"
    hist
    |> inc_count_at(index)
    |> update_min(value)
    |> update_max(value)
    |> inc_total_count
  end

  defp update_max(hist, value) do
    case hist.max && hist.max > value do
      true -> hist
      _ -> %{hist | max: value}
    end
  end

  defp update_min(hist, value) do
    case hist.min && hist.min < value do
      true -> hist
      _ -> %{hist | min: value}
    end
  end

  defp inc_total_count(hist) do
    %{hist | total_count: hist.total_count + 1}
  end

  defp counts_index(hist, value) do
    assert(value > 0, "Histogram recorded value cannot be negative.")
    index = bucket_index(hist, value)
    sub_index = sub_bucket_index(hist, value, index)
    counts_index(hist, index, sub_index)
  end

  defp counts_index(hist, index, sub_index) do
    IO.inspect([index, sub_index])
    assert(sub_index < hist.sub_bucket_count, "Error")
    assert(index == 0 or sub_index >= hist.sub_bucket_half_count, "Error")
    bucket_base_index = :erlang.bsl(index + 1, hist.sub_bucket_half_count_magnitude)
    offset_in_bucket = sub_index - hist.sub_bucket_half_count
    bucket_base_index - offset_in_bucket
  end

  defp bucket_index(hist, value) do
    hist.leading_zero_count - leading_zeros(:erlang.bor(value, hist.sub_bucket_mask))
  end

  defp sub_bucket_index(hist, value, index) do
    trunc(:erlang.bsr(value, index + hist.unit_magnitude))
  end

  defp inc_count_at(hist, index) do
    count = :array.get(index, hist.counts)
    counts = :array.set(index, count + 1, hist.counts)
    %{hist | counts: counts}
  end

  # Internal

  ## Initialization

  defp init(hist) do
    largest_unit_resolution = trunc(2 * :math.pow(10, hist.digits))
    unit_magnitude = trunc(:math.log(hist.lowest)/:math.log(2));
    sub_bucket_count_magnitude = ceil(:math.log(largest_unit_resolution)/:math.log(2))
    sub_bucket_half_count_magnitude =
      case sub_bucket_count_magnitude > 1 do
        true -> sub_bucket_count_magnitude
        false -> 1
      end - 1

    sub_bucket_count = trunc(:math.pow(2, sub_bucket_half_count_magnitude + 1))
    sub_bucket_half_count = trunc(sub_bucket_count / 2)
    sub_bucket_mask = :erlang.bsl(round(sub_bucket_count - 1), unit_magnitude)

    leading_zero_count = 64 - unit_magnitude - sub_bucket_half_count_magnitude - 1

    hist = %{hist |
             unit_magnitude: unit_magnitude,
             sub_bucket_count: sub_bucket_count,
             sub_bucket_half_count: sub_bucket_half_count,
             sub_bucket_half_count_magnitude: sub_bucket_half_count_magnitude,
             sub_bucket_mask: sub_bucket_mask,
             leading_zero_count: leading_zero_count}

    hist = determine_array_length(hist)
    %{hist | counts: :array.new([hist.counts_length, :fixed, {:default, 0}])}
  end

  defp determine_array_length(hist) do
    assert(hist.highest >= 2 * hist.lowest,
              "highest (trackable value) must be >= 2 * lowest (discernible value)")
    hist
    |> buckets_needed_to_cover_value
    |> length_for_bucket_count
  end

  defp buckets_needed_to_cover_value(hist) do
    smallest_value = :erlang.bsl(hist.sub_bucket_count, hist.unit_magnitude)
    buckets_needed = _buckets_needed(smallest_value, 1, hist.highest)
    %{hist | bucket_count: buckets_needed}
  end

  defp _buckets_needed(smallest_value, buckets_needed, highest) when smallest_value <= highest do
    buckets_needed = case smallest_value > (@max_value / 2) do
                       true -> buckets_needed + 1
                       false -> buckets_needed
                     end
    smallest_value = :erlang.bsl(smallest_value, 2)
    _buckets_needed(smallest_value, buckets_needed + 1, highest)
  end
  defp _buckets_needed(_, buckets_needed, _) do
    buckets_needed
  end

  defp length_for_bucket_count(hist) do
    counts_length = trunc((hist.bucket_count + 1) * hist.sub_bucket_count / 2)
    %{hist | counts_length: counts_length}
  end

  defp assert(expr, msg) do
    case expr do
      true -> :ok
      false -> throw({:badarg, msg})
    end
  end
end
