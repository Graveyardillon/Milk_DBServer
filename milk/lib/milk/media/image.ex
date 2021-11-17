defmodule Milk.Media.Image do
  alias Milk.CloudStorage.Objects
  # alias Milk.Media.Image

  def get(url) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(url)
    {:ok, body}
  end

  def read_image(path) do
    path
    |> File.read()
    |> case do
      {:ok, image} ->
        {:ok, image}

      {:error, _} ->
        {:error, "image not found"}
    end
  end

  def read_image_prod(name) do
    {:ok, object} = Objects.get(name)
    __MODULE__.get(object.mediaLink)
  end
end
