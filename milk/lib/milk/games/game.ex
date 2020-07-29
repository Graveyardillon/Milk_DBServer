defmodule Milk.Games.Game do

  use Milk.Schema
  import Ecto.Changeset

  schema "games" do
    field :icon_path, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:title, :icon_path])
    |> validate_required([:title, :icon_path])
  end
end
