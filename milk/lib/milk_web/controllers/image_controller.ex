defmodule MilkWeb.ImageController do
  use MilkWeb, :controller

  alias Milk.Media.Image

  require ExImageInfo

  def get_by_path(conn, %{"path" => path}) do
    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev ->
        Image.read_image(path)

      :test ->
        Image.read_image(path)

      _ ->
        Image.read_image_prod(path)
    end
    |> case do
      {:ok, image} ->
        image
        |> ExImageInfo.info()
        |> case do
          {"image/png", _, _, _} ->
            conn
            |> put_resp_content_type("image/png")
            |> send_resp(200, image)
          _ ->
            conn
            |> put_resp_content_type("image/jpg")
            |> send_resp(200, image)
        end

      {:error, error} ->
        json(conn, %{error: error})
    end
  end
end
