Grog
====

Grog is an attempt to build a lightweight but scalable load and stress testing tool in Elixir. There are many benefits of using Elixir for this purposes, the main one being it runs on the Erlang VM, which washas built-in support for lightweight processes.

The name of the project is a reference to Monkey Island's beverage, we thought it was a cool name and sort of made sense in the context of the language being used (i.e. Elixir).

# Rationale

After trying some load testing tools, none of them fulfilled two basic needs we had:

1. Provide a simple and flexible API to implement the clients logic.
2. Low CPU and memory consumption, to be able to maximize the number of virtual clients being simulated.

So we set out to try to build a system with these two main goals in mind.

# Roadmap

1. Create a simple, flexible API to define clients.
2. Basic spawning mechanism for clients.
3. Metrics endpoints.
4. Web UI.
5. Distribution.
