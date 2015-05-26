defmodule Grog.CLI do
  require Logger
  @moduledoc """
  Implements the command line interface code that
  loads the Grog specification and starts the web
  server.
  """

  @defaults %{file: "grog_clients.exs",
              count: 100,
              rate: 10}

  @doc """
  escript entry point function.
  """
  def main(argv) do
    {opts, _, _} = OptionParser.parse(argv)
    # Logger.configure([level: :error])
    run(opts)
  end

  defp run(opts) do
    path = opts[:file] || @defaults.file
    modules = Kernel.ParallelCompiler.files([path])

    case Enum.filter(modules, &client?/1) do
      [] ->
        error("No Grog.Client(s) defined in '#{path}'.")
      clients ->
        count = opts[:count] || @defaults.count
        rate = opts[:rate] || @defaults.rate
        info("Starting #{inspect count} #{inspect clients} client(s) at #{inspect rate} clients/sec")
        Grog.start(clients, count, rate)
        IO.inspect(Grog.status)
        :timer.sleep(5000)
        IO.inspect(Grog.status)
    end
  end

  defp info(msg) do
    IO.puts "#{IO.ANSI.white}#{msg}"
  end

  defp error(msg) do
    IO.puts "#{IO.ANSI.red}Error: #{msg}"
    :erlang.halt(1)
  end

  defp client?(module) do
    [true] == module.__info__(:attributes)[:grog_client]
  end
end
