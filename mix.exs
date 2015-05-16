defmodule Grog.Mixfile do
  use Mix.Project

  def project do
    [app: :grog,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Grog.App, []},
     registered: [Grog.Client.Supervisor],
     applications: [:logger, :exreloader, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    #[{:sync, github: "jfacorro/sync", tag: "master", only: :dev},
    [{:exreloader, github: "jfacorro/exreloader", tag: "master", only: :dev},
     {:eep, github: "virtan/eep", tag: "v1.1", only: :dev},
     {:httpoison, "~> 0.6.2"}
    ]
  end
end
