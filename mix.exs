defmodule Grog.Mixfile do
  use Mix.Project

  def project do
    [app: :grog,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     escript: escript]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Grog.App, []},
     registered: [Grog.Client.Supervisor],
     applications: [:logger, :shotgun, :cowboy, :plug]]
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
    [{:cowboy, github: "ninenines/cowboy", tag: "1.0.1", override: true},
     {:plug, "~> 0.12.2"},
     {:shotgun, github: "inaka/shotgun", tag: "master"},
     {:ex_edn, github: "jfacorro/ExEdn", tag: "0.1.1"},
     # Override these two deps because they conflict between cowboy and gun.
     {:cowlib, "~> 1.0.0", override: true},
     {:ranch, "~> 1.0.0", override: true},

     {:exreloader, github: "jfacorro/exreloader", tag: "master", only: :dev},
     {:eep, github: "virtan/eep", tag: "v1.1", only: :dev},
     {:katana, github: "inaka/erlang-katana", tag: "0.2.5", only: :dev}
    ]
  end

  # Configuration used to generate an escript file.
  #
  # The module specified in :main_module should have a
  # main/1 function declared.
  #
  # Type `mix help escript.build` for more information
  def escript do
    [main_module: Grog.CLI,
     path: "bin/grog"]
  end
end
