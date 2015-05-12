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
end
