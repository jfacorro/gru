defmodule Grog.Http do

  def interval url, sleep_ms, times do
    spawn fn -> periodic_worker(url, sleep_ms, times) end
  end

  defp periodic_worker _, _, 0 do
    IO.puts "Done GETting"
    :ok
  end
  defp periodic_worker url, sleep_ms, times do
    IO.puts "GETting #{:io_lib.format("~p", [times])}"
    HTTPoison.get! url
    :timer.sleep sleep_ms
    times = case times do
              :infinity -> :infinity
              _ -> times - 1
            end
    periodic_worker url, sleep_ms, times
  end
end
