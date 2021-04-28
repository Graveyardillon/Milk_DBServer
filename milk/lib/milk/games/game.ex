defmodule Milk.Games.Game do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "games" do
    field :icon_path, :string
    field :title, :string
    has_many :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:title, :icon_path])
    |> validate_required([:title])
  end
end
