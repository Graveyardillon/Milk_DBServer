defmodule MilkWeb.ImageController do
  use MilkWeb, :controller

  def get_icon(conn, %{"path" => path}) do
    # case File.read("./static/image/profile_icon/#{path}.jpg") do
    case File.read(path) do # iconはなぜかフルパス
      {:ok, image} ->
        conn
        |> put_resp_content_type("image/jpeg", nil)
        |> send_resp(200, image)
        
      _ ->
        json(conn, %{error: "image not found"})
    end
  end

  def get_thumbnail(conn, %{"path" => path}) do
    case File.read("./static/image/tournament_thumbnail/#{path}.jpg") do
      {:ok, image} ->
        conn
        |> put_resp_content_type("image/jpeg", nil)
        |> send_resp(200, image)

      _ ->
        json(conn, %{error: "image not found"})
    end
  end
end