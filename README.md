Gru
====

[![Travis](https://img.shields.io/travis/jfacorro/gru.svg?style=flat-square)](https://travis-ci.org/jfacorro/gru)

<img src="https://github.com/jfacorro/gru/blob/20eea9a39f646cdea57aedee2b4e5cfb1595da74/web/img/logo.png" align="right" style="float:right" />

Gru is an attempt to build a lightweight but scalable load/stress testing tool. Using Elixir for this purpose has many benefits, the main one being the Erlang VM, which has built-in support for lightweight processes.


# Rationale

After trying some load testing tools, none of them fulfilled two basic needs:

1. Provide a simple and flexible API to implement the clients (minions) logic.
2. Low CPU and memory consumption, to be able to maximize the number of minions being simulated.

So we set out to try to build a system with these two main goals in mind.

# Roadmap

1. Create a simple, flexible API to define minions. *DONE*
2. Basic spawning mechanism for minions. *DONE*
3. Metrics endpoints. *DONE*
4. Web UI. *90% DONE*
5. Distribution.

# Building

There are two parts that need to be built: the frontend website (CloureScript) and the backend server (Elixir).

Building both of them is as simple as just running the following command in your shell:

```
make
```

This assumes you have the following tools available in your devdelopment environment:

- [`make`](https://www.gnu.org/software/make/)
- [`mix`](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)
- [`lein`](https://github.com/technomancy/leiningen/)

## Executable

There's a way of generating an executable file in the form of an Elixir script by
running `make escript`. A `gru` executable file will be created under the `bin` folder.
This executable currently doesn't include the web server, but it will in the future.

# Development

Once you have built the project you can start an Elixir shell by running `make shell`, which will show you something like:

```
iex --name gru@`hostname` -pa _build/dev/consolidated -S mix
Erlang/OTP 17 [erts-6.3] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.0.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(gru@host)1>
```

If you want to start the web server using one of the minions in the `examples`
folder just execute the following:

```
iex(gru@host)1> Gru.CLI.main(["--file", "examples/status-minion.exs"])
```