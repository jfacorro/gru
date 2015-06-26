defmodule Gru.CLI do
  require Logger
  @moduledoc """
  Implements the command line interface code that loads the Gru
  specification and starts the web server.
  """

  @defaults %{file: "minions.exs",
              count: 100,
              rate: 10,
              port: 8888,
              root: "web"}

  @doc """
  escript entry point function.
  """
  def main(argv) do
    {opts, _, _} = OptionParser.parse(argv)
    Logger.configure([level: :error])
    opts = :maps.from_list(opts)

    if opts[:help], do: help

    try do
      run(opts)
    rescue
      e -> error(e.message)
    end
  end

  defp help do
    info "Usage: gru [--file <path>] [--count <count>] [--rate <rate>] --no-web"
  end

  defp run(opts) do
    path = opts[:file] || @defaults.file

    if not File.exists? path do
      raise ArgumentError, message: "No minions file found: #{path}"
    end

    modules = Kernel.ParallelCompiler.files([path])
    minions = Enum.filter(modules, &minion?/1)

    if Enum.empty? minions do
      raise ArgumentError, message: "No Gru.Minion(s) defined in '#{path}'."
    end

    start(minions, opts)
  end

  defp start(minions, %{no_web: true} = opts) do
    count = opts[:count] || @defaults.count
    rate = opts[:rate] || @defaults.rate

    info("Starting #{inspect count} #{inspect minions} minion(s) at #{inspect rate} minions/sec")
    Gru.start(minions, count, rate)
    menu(minions, opts)
  end
  defp start(minions, opts) do
    port = opts[:port] || @defaults.port
    root = opts[:root] || @defaults.root

    info("Starting Gru web server at http://localhost:#{inspect port}...")
    info("Minions registered for work: #{inspect minions}")
    Gru.Web.start(minions, port, root)
    # Infinitely read form stdin
    IO.read(:all)
  end

  defp menu(minions, opts) do
    info("Press 'q' to  quit, 's' to show current status or 'r' to restart: ")
    case String.strip(IO.read(:line)) do
      "s" ->
        output("#{inspect Gru.status}")
      "r" ->
        Gru.stop
        start(minions, opts)
      "q" ->
        info("Bye!")
        :erlang.halt(0)
      _ ->
        error("Invalid option.", false)
    end
    menu(minions, opts)
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

  defp minion?(module) do
    [true] == module.__info__(:attributes)[:minion]
  end
end
