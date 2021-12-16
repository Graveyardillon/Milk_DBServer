defmodule Milk.Platforms do
  @moduledoc """
  The platforms context.
  """

  import Common.Sperm
  import Ecto.Query, warn: false

  alias Milk.Platforms.Platform
  alias Milk.Repo

  def create_basic_platforms() do
    platform_names = [
      "pc", "mobile", "the other"
    ]

    Platform
    |> where([p], p.name in ^platform_names)
    |> Repo.all()
    |> Enum.map(&(&1.name))
    ~> names

    platform_names
    |> Enum.reject(&(&1 in names))
    |> Enum.each(&create_platform(%{"name" => &1}) |> IO.inspect())
  end

  def create_platform(attrs \\ %{}) do
    %Platform{}
    |> Platform.changeset(attrs)
    |> Repo.insert()
  end
end
