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
    Logger.configure([level: :error])
    run(opts)
    menu(opts)
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
    end
  end

  defp menu(opts) do
    info("Press 'q' to  quit, 's' to show current status or 'r' to restart: ")
    case String.strip(IO.read(:line)) do
      "q" ->
        :erlang.halt(0)
      "s" ->
        status = to_string(:io_lib.format("~p", [Grog.status]))
        output(status)
      "r" ->
        Grog.stop
        run(opts)
      _ ->
        error("Invalid option.", false)
    end
    menu(opts)
  end

  defp output(msg) do
    IO.puts "#{IO.ANSI.yellow}#{msg}"
  end

  defp info(msg) do
    IO.puts "#{IO.ANSI.white}#{msg}"
  end

  defp error(msg, halt \\ true) do
    IO.puts "#{IO.ANSI.red}Error: #{msg}"

    if halt, do: :erlang.halt(1)
  end

  defp client?(module) do
    [true] == module.__info__(:attributes)[:grog_client]
  end
end
