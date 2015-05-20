defmodule Grog.Utils do
  @type element :: any

  @doc """
  Returns an infinite stream of xs.
  """
  @spec repeat(element) :: Enumerable.t
  def repeat(x) do
    Stream.repeatedly fn -> x end
  end

  @doc """
  Returns a stream of length n of xs.
  """
  @spec repeat(element, integer) :: Enumerable.t
  def repeat(x, n) when n >= 0 do
    Stream.take(repeat(x), n)
  end

  @doc """
  Prints the Erlang source code for any loaded module.
  """
  @spec prn_module_erl_src(atom) :: Enumerable.t
  def prn_module_erl_src module do
    {:file, file} = :code.is_loaded(module)
    {:ok, erl_src} = :ktn_code.beam_to_string(file)
    IO.puts erl_src
  end

  @doc """
  Runs the expresion provided and returns a tuple of the form
  `{time, value}` where `time` is the time it took the expression
  to complete in microseconds and `value` is the the value of the
  expression provided.
  """
  defmacro time(expr) do
    quote do
      :timer.tc(fn -> unquote(expr) end)
    end
  end

  @doc """
  Profile the currently running code and generate a kcachegrind file.
  """
  def profile(time \\ 1000)do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    ymd_hhmmss = "#{inspect y}#{inspect m}#{inspect d}#{inspect hh}#{inspect mm}#{inspect ss}"
    filename = 'filename-' ++ String.to_char_list(ymd_hhmmss)
    :eep.start_file_tracing(filename)
    :timer.sleep(time)
    :eep.stop_tracing()
    :eep.convert_tracing(filename)
  end

  @doc """
  Returns a uniform random number between `from` and `to`.
  """
  def uniform(from, to) when from < to do
    ensure_seed()
    from + :random.uniform(to - from) - 1
  end

  @doc """
  Returns a uniform random number between `0` and `to`.
  """
  def uniform(to) do
    uniform(0, to)
  end

  @doc """
  Return the ceiling of the number provided.
  """
  def ceil(n) do
    x = trunc(n)
    case n - x > 0 do
      true -> x + 1
      false -> x
    end
  end

  @doc """
  Returns the  number of leading zeros of the provided integer.
  """
  def leading_zeros(0) do
    64
  end
  def leading_zeros(n) when is_integer(n) do
    _leading_zeros(n, 0)
  end

  defp _leading_zeros(0, x) do
    leading_zeros(0) - x
  end
  defp _leading_zeros(n, x) do
    _leading_zeros(:erlang.bsr(n, 1), x + 1)
  end


  ## Internal

  defp ensure_seed() do
    case :erlang.get(:random_seed) do
      :undefined ->
        :random.seed(:os.timestamp())
      _ ->
        :ok
    end
  end
end
