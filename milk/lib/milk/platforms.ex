defmodule Milk.Platforms do
  @moduledoc """
  The platforms context.
  """

  import Ecto.Query, warn: false

  alias Milk.Repo
  alias Milk.Platforms.Platform

  def create_basic_platforms() do
    platform_names =
      Platform
      |> where([p], p.name == "pc" or p.name == "mobile")
      |> Repo.all
      |> Enum.map(fn platform -> 
        platform.name
      end)

    unless "pc" in platform_names do
      create_platform(%{"name" => "pc"})
    end

    unless "mobile" in platform_names do
      create_platform(%{"name" => "mobile"})
    end
  end

  def create_platform(attrs \\ %{}) do
    %Platform{}
    |> Platform.changeset(attrs)
    |> Repo.insert()
  end
end