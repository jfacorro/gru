defmodule Gru.Web.Utils do
  require Plug.Router

  defmacro static(at, from \\ nil) do
    expr = quote do
      "/" <> Enum.join(var!(conn).path_info, "/")
    end

    quote do
      get unquote(at) do
        root = Map.get(var!(conn).private, :root)
        path = root <> unquote(from || expr)
        ext = :filename.extension(path) |> String.replace(".", "")
        mime_types =  %{"js" => "application/javascript",
                        "css" => "text/css",
                        "png" => "image/png",
                        "jpg" => "image/jpg",
                        "html" => "text/html"}
        case File.read(path) do
          {:ok, content} ->
            var!(conn)
            |> put_resp_header("Content-Type", Map.get(mime_types, ext, "text/plain"))
            |> send_resp(200, content)
          {:error, :enoent} ->
            send_resp(var!(conn), 500, "Web server not available")
        end
      end
    end
  end
end
