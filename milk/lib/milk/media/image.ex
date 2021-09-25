defmodule Milk.Media.Image do
  alias Milk.CloudStorage.Objects
  #alias Milk.Media.Image

  def get(url) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(url)
    {:ok, body}
  end

  def read_image(path) do
    File.read(path)
    |> case do
      {:ok, image} ->
        {:ok, image}

      {:error, _} ->
        {:error, "image not found"}
    end
  end

  def read_image_prod(path) do
    object = Objects.get(path)

    case get(object.mediaLink) do
      {:ok, image} ->
        {:ok, image}

      _ ->
        {:error, "image not found"}
    end
  end
end
