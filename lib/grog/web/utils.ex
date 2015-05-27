defmodule Grog.Web.Utils do
  require Plug.Router

  defmacro static(at, root, from \\ nil) do
    expr = quote do
      "/" <> Enum.join(var!(conn).path_info, "/")
    end
    quote do
      get unquote(at) do
        path = unquote(root) <> unquote(from || expr)
        case File.read(path) do
          {:ok, content} ->
            send_resp(var!(conn), 200, content)
          {:error, :enoent} ->
            send_resp(var!(conn), 500, "Web server not available")
        end
      end
    end
  end
end
