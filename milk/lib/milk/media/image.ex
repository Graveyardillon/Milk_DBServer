defmodule Milk.Media.Image do
  alias Milk.CloudStorage.Objects
  #alias Milk.Media.Image

  def get(url) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(url)
      |> IO.inspect(label: :httpoison_get_response)
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
    name
    |> IO.inspect(label: :path_in_image)
    |> Objects.get()
    |> IO.inspect(label: :objects_get_in_image)
    |> Map.get(:mediaLink)
    |> __MODULE__.get()
    |> case do
      {:ok, image} ->
        {:ok, image}

      _ ->
        {:error, "image not found"}
    end
  end
end
