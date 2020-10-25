defmodule Milk.Platforms.Platform do
  use Milk.Schema
  import Ecto.Changeset

  schema "platforms" do
    field :name, :string
  end

  def changeset(platform, attrs) do
    platform
    |>cast(attrs, [:name])
    |>validate_required([:name])
  end
end