defmodule Gru.CLI do
  require Logger
  @moduledoc """
  Implements the command line interface code that loads the Gru
  specification and starts the web server.
  """

  @defaults %{file: "gru_clients.exs",
              count: 100,
              rate: 10}

  @doc """
  escript entry point function.
  """
  def main(argv) do
    {opts, _, _} = OptionParser.parse(argv)
    Logger.configure([level: :error])

    if opts[:help], do: help

    try do
      run(opts)
    rescue
      e -> error(e.message)
    end
  end

  defp help do
    info "Usage: gru [--file <path>] [--count <count>] [--rate <rate>]"
  end

  defp run(opts) do
    path = opts[:file] || @defaults.file

    if not File.exists? path do
      raise ArgumentError, message: "No clients file found."
    end

    modules = Kernel.ParallelCompiler.files([path])
    clients = Enum.filter(modules, &client?/1)

    if Enum.empty? clients do
      raise ArgumentError, message: "No Gru.Client(s) defined in '#{path}'."
    end

    count = opts[:count] || @defaults.count
    rate = opts[:rate] || @defaults.rate
    start(clients, count, rate)
  end

  defp start(clients, count, rate) do
      info("Starting #{inspect count} #{inspect clients} client(s) at #{inspect rate} clients/sec")
      Gru.start(clients, count, rate)
      menu(clients, count, rate)
  end

  defp menu(clients, count, rate) do
    info("Press 'q' to  quit, 's' to show current status or 'r' to restart: ")
    case String.strip(IO.read(:line)) do
      "s" ->
        output("#{inspect Gru.status}")
      "r" ->
        Gru.stop
        start(clients, count, rate)
      "q" ->
        info("Bye!")
        :erlang.halt(0)
      _ ->
        error("Invalid option.", false)
    end
    menu(clients, count, rate)
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
    [true] == module.__info__(:attributes)[:gru_client]
  end
end
