defmodule Grog.Client do

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [deftask: 2]
      @before_compile Grog.Client
      # Accumulate tasks with their weights
      Module.register_attribute(__MODULE__, :tasks, accumulate: true)

      def __init__ do
        Dict.merge(%{}, unquote(opts))
      end
    end
  end

  defmacro __before_compile__(_env) do
    tasks = Module.get_attribute(__CALLER__.module, :tasks)
            |> Enum.flat_map( fn {name, weight} -> Grog.Utils.repeat(name, weight) end)
            |> Enum.reverse
    quote do
      def __tasks__, do: unquote(tasks)
    end
  end

  defmacro deftask(definition = {name, _, _}, do: contents) do
    quote do
      Grog.Client.__on_definition__(__ENV__, unquote(name))
      def unquote(definition), do: unquote(contents)
    end
  end

  def __on_definition__(env, name) do
    weights = Module.get_attribute(env.module, :weight) || 1
    Module.put_attribute(env.module, :tasks, {name, weights})
  end
end
