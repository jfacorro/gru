defmodule Grog.HdrHistogram do
  alias Grog.HdrHistogram
  import Grog.Utils

  defstruct lowest: nil, highest: nil, digits: nil,
  bucket_count: nil,
  sub_bucket_count: nil,

  sub_bucket_half_count: nil,
  sub_bucket_half_count_magnitude: nil,
  sub_bucket_mask: nil,

  unit_magnitude: nil,

  leading_zero_count: nil,
  counts_length: nil,
  counts: nil, min: nil, max: nil,
  total_count: 0

  @max_value 9223372036854775807

  def new(lowest, highest, digits \\ 3) do
    assert(lowest >= 1, "lowest (discernible value) must be >= 1")
    assert(highest >= 2 * lowest,
           "highest (trackable value) must be >= 2 * lowest (discernible value)")
    assert(digits >= 0 and digits <= 5,
           "(number of significant) digits must be between 0 and 5")

    hist = %HdrHistogram{highest: highest, lowest: lowest, digits: digits}
    init(hist)
  end

  def record(hist, value) do
    index = counts_index(hist, value)

    hist
    |> inc_count_at(index)
    |> update_min(value)
    |> update_max(value)
    |> inc_total_count
  end

  def percentile(hist, percentile) do
    percentile = min(percentile, 100)
    count_percentile = trunc(percentile / 100 * hist.total_count + 0.5)
    count_percentile = max(count_percentile, 0)
    IO.puts "count_perc #{inspect count_percentile}"

    iterate_fn = fn {index, count} ->
      {index + 1,
       count + :array.get(index, hist.counts)}
    end
    drop_fn = fn {_, count} -> count < count_percentile end

    index = Stream.iterate({0, 0}, iterate_fn)
            |> Stream.drop_while(drop_fn)
            |> Enum.take(1)
            |> List.first
            |> elem(0)

    value_at_index(hist, index)
  end

  ## Initialization

  defp init(hist) do
    largest_unit_resolution = trunc(2 * :math.pow(10, hist.digits))
    unit_magnitude = trunc(:math.log(hist.lowest) / :math.log(2));
    sub_bucket_count_magnitude = ceil(:math.log(largest_unit_resolution) / :math.log(2))
    sub_bucket_half_count_magnitude =
      if sub_bucket_count_magnitude > 1 do
        sub_bucket_count_magnitude
      else
        1
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
    smallest_value = :erlang.bsl(smallest_value, 1)
    _buckets_needed(smallest_value, buckets_needed + 1, highest)
  end
  defp _buckets_needed(_, buckets_needed, _) do
    buckets_needed
  end

  defp length_for_bucket_count(hist) do
    counts_length = trunc((hist.bucket_count + 1) * hist.sub_bucket_count / 2)
    %{hist | counts_length: counts_length}
  end

  ## Keep track of global values (min, max, total count)

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

  ## Calculate counts_index

  defp counts_index(hist, value) do
    assert(value >= 0, "Histogram recorded value cannot be negative.")
    index = bucket_index(hist, value)
    sub_index = sub_bucket_index(hist, value, index)
    counts_index(hist, index, sub_index)
  end

  defp counts_index(hist, index, sub_index) do
    # IO.inspect([sub_index, hist.sub_bucket_count])
    assert(sub_index < hist.sub_bucket_count,
           "Error: sub_index < hist.sub_bucket_count")
    # IO.inspect([index, sub_index, hist.sub_bucket_half_count])
    assert(index == 0 or sub_index >= hist.sub_bucket_half_count,
           "Error: index == 0 or sub_index >= hist.sub_bucket_half_count")
    bucket_base_index = :erlang.bsl(index + 1, hist.sub_bucket_half_count_magnitude)
    offset_in_bucket = sub_index - hist.sub_bucket_half_count
    bucket_base_index + offset_in_bucket
  end

  defp bucket_index(hist, value) do
    hist.leading_zero_count - leading_zeros(:erlang.bor(value, hist.sub_bucket_mask))
  end

  defp sub_bucket_index(hist, value, index) do
    trunc(:erlang.bsr(value, index + hist.unit_magnitude))
  end

  defp inc_count_at(hist, index) do
    current = :array.get(index, hist.counts)
    counts = :array.set(index, current + 1, hist.counts)
    %{hist | counts: counts}
  end

  ## Returns the value at the given index
  defp value_at_index(hist, index) do
    bucket_index = :erlang.bsr(index, hist.sub_bucket_half_count_magnitude) - 1
    sub_bucket_index = :erlang.band(index, (hist.sub_bucket_half_count - 1)) + hist.sub_bucket_half_count

    if bucket_index < 0 do
      sub_bucket_index = sub_bucket_index - hist.sub_bucket_half_count
      bucket_index = 0
    end

    :erlang.bsl(sub_bucket_index, (bucket_index + hist.unit_magnitude))
  end
end

defimpl Inspect, for: Grog.HdrHistogram do
  import Inspect.Algebra

  def inspect(histogram, opts) do
    concat(["#HdrHistogram<", to_doc(:array.to_list(histogram.counts), opts),
            ", lowest=", inspect(histogram.lowest),
            ", highest=", inspect(histogram.highest),
            ", digits=", inspect(histogram.digits),
            ", counts_length=", inspect(histogram.counts_length),
            ">"])
  end
end
