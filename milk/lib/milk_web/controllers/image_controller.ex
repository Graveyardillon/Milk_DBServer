defmodule MilkWeb.ImageController do
  use MilkWeb, :controller

  alias Milk.Media.Image
  alias Milk.Tournaments

  require ExImageInfo

  defp load_image(path) do
    case Application.get_env(:milk, :environment) do
      :dev ->
        Image.read_image(path)

      :test ->
        Image.read_image(path)

      _ ->
        Image.read_image_prod(path)
    end
  end

  def get_by_path(conn, %{"path" => path}) do
    path
    |> load_image()
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

  def get_thumbnail_by_tournament_id(conn, %{"tournament_id" => id}) do
    case Tournaments.load_tournament(id) do
      nil ->
        json(conn, %{result: false})

      tournament ->
        tournament.thumbnail_path
        |> load_image()
        |> case do
          {:ok, image} ->
            conn
            |> put_resp_content_type("image/jpg", nil)
            |> send_resp(200, image)

          {:error, error} ->
            json(conn, %{error: error})
        end
    end
  end
end
