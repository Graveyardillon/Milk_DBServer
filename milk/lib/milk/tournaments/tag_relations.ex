defmodule Milk.Tournaments.TagRelations do
  use Milk.Schema
  import Ecto.Changeset

  alias Milk.Tournaments.{
    Tag,
    Tournament,
  }

  @primary_key false
  schema "tournament_tag_relations" do
    belongs_to :tag, Tag
    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(tag_relations, attrs \\ %{}) do
    tag_relations
    |> cast(attrs, [:tag_id, :tournament_id])
    |> validate_required([:tag_id, :tournament_id])
  end
end
