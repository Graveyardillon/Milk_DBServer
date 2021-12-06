defmodule Milk.Platforms do
  @moduledoc """
  The platforms context.
  """

  import Common.Sperm
  import Ecto.Query, warn: false

  alias Milk.Platforms.Platform
  alias Milk.Repo

  def create_basic_platforms() do
    Platform
    |> where([p], p.name == "pc" or p.name == "mobile")
    |> Repo.all()
    |> Enum.map(&(&1.name))
    ~> platform_names

    unless "pc" in platform_names,     do: create_platform(%{"name" => "pc"})
    unless "mobile" in platform_names, do: create_platform(%{"name" => "mobile"})
  end

  def create_platform(attrs \\ %{}) do
    %Platform{}
    |> Platform.changeset(attrs)
    |> Repo.insert()
  end
end
