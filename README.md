Gru
====

[![Travis](https://img.shields.io/travis/jfacorro/gru.svg?style=flat-square)](https://travis-ci.org/jfacorro/gru)

Gru is an attempt to build a lightweight but scalable load/stress testing tool. Using Elixir for this purpose has many benefits, the main one being the Erlang VM, which has built-in support for lightweight processes.

# Rationale

After trying some load testing tools, none of them fulfilled two basic needs:

1. Provide a simple and flexible API to implement the clients (minions) logic.
2. Low CPU and memory consumption, to be able to maximize the number of minions being simulated.

So we set out to try to build a system with these two main goals in mind.

# Roadmap

1. Create a simple, flexible API to define minions.
2. Basic spawning mechanism for minions.
3. Metrics endpoints.
4. Web UI.
5. Distribution.
