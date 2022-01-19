defmodule Milk.Tournaments.Tag do
  use Milk.Schema
  import Ecto.Changeset

  alias Milk.Tournaments.{
    Tournament,
    TagRelations
  }

  schema "tournament_tags" do
    field :name, :string

    # has_many :relations, TagRelations
    many_to_many :tournaments, Tournament, join_through: TagRelations

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
