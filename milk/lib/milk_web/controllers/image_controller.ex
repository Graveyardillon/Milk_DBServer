defmodule MilkWeb.ImageController do
  use MilkWeb, :controller

  alias Milk.Media.Image

  def get_by_path(conn, %{"path" => path}) do
    result =
      case Application.get_env(:milk, :environment) do
        :dev ->
          Image.read_image(path)

        :test ->
          Image.read_image(path)

        _ ->
          Image.read_image_prod(path)
      end

    case result do
      {:ok, image} ->
        conn
        |> put_resp_content_type("image/jpg", nil)
        |> send_resp(200, image)

      {:error, error} ->
        json(conn, %{error: error})
    end
  end
end
