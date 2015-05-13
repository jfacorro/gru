defmodule Grog.HTTP do
  use HTTPoison.Base
  alias Grog.Metrics.Server, as: Metrics
  alias Grog.Metrics.Count
  alias Grog.Metrics.Average

  def request(method, url, body \\ "", headers \\ [], opts \\ []) do
    {time, value} = :timer.tc(HTTPoison, :request, [method, url, body, headers, opts])

    name = Keyword.get(opts, :name, url)
    Metrics.report(%Count{name: name}, 1)
    Metrics.report(%Average{name: name}, time / 1000)

    value
  end

  def request!(method, url, body \\ "", headers \\ [], opts \\ []) do
    {time, value} = :timer.tc(HTTPoison, :request!, [method, url, body, headers, opts])

    name = Keyword.get(opts, :name, url)
    Metrics.report(%Count{name: name}, 1)
    Metrics.report(%Average{name: name}, time / 1000)

    value
  end
end
