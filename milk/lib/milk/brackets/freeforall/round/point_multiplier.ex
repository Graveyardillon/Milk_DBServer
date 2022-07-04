defmodule Milk.Brackets.FreeForAll.Round.PointMultiplier do
  use Milk.Schema

  alias Milk.Brackets.FreeForAll.Round.MatchInformation
  alias Milk.Brackets.FreeForAll.PointMultiplierCategory, as: Category

  schema "brackets_freeforall_round_pointmultipliers" do
    field :point, :integer

    belongs_to :match_information, MatchInformation
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(multipliers, attrs) do
    multipliers
    |> cast(attrs, [:point, :match_information_id, :category_id])
    |> foreign_key_constraint(:match_information_id)
    |> foreign_key_constraint(:category_id)
  end
end
