defmodule Milk.Tournaments.MapSelection do
  use Milk.Schema

  import Ecto.Changeset

  schema "map_selections" do
    field :state, :string, default: "not_selected"
    field :small_id, :integer
    field :large_id, :integer

    belongs_to :map, Milk.Tournaments.Map

    timestamps()
  end

  @doc false
  def changeset(map_selection, attrs) do
    map_selection
    |> cast(attrs, [:state, :map_id, :small_id, :large_id])
    |> foreign_key_constraint(:map_id)
  end
end
