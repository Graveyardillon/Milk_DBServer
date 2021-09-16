defmodule MilkWeb.ImageController do
  use MilkWeb, :controller

  def get_by_path(conn, %{"path" => path}) do
    case File.read(path) do
      {:ok, image} ->
        conn
        |> put_resp_content_type("image/jpg", nil)
        |> send_resp(200, image)
        
      _ ->
        json(conn, %{error: "image not found"})
    end
  end
end