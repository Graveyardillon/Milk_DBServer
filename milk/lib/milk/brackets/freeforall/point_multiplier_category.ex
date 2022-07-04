defmodule Milk.Brackets.FreeForAll.PointMultiplierCategory do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.Bracket

  schema "brackets_freeforall_pointmultipliercategories" do
    field :name, :string
    field :multiplier, :float

    belongs_to :bracket, Bracket

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :multiplier, :bracket_id])
    |> foreign_key_constraint(:bracket_id)
  end
end
