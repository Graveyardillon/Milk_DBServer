defmodule Milk.Tournaments.MapSelection do
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          state: String.t(),
          small_id: integer(),
          large_id: integer(),
          map_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "map_selections" do
    field :state, :string, default: "not_selected"
    field :small_id, :integer
    field :large_id, :integer

    belongs_to :map, Milk.Tournaments.Map

    timestamps()
  end

  def changeset(attrs), do: __MODULE__.changeset(%__MODULE__{}, attrs)

  @doc false
  def changeset(map_selection, attrs) do
    map_selection
    |> cast(attrs, [:state, :map_id, :small_id, :large_id])
    |> foreign_key_constraint(:map_id)
  end
end
