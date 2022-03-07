defmodule Milk.Tournaments.Rules.FreeForAll.Round.TeamPointMultiplier do
  @moduledoc """
  キルポイントとかのスコアを実際に記録しておくためのやつ（チーム）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.TeamMatchInformation
  alias Milk.Tournaments.Rules.FreeForAll.PointMultiplierCategory, as: Category

  schema "tournaments_rules_freeforall_round_teampointmultipliers" do
    field :point, :integer

    belongs_to :team_match_information, TeamMatchInformation
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(multipliers, attrs) do
    multipliers
    |> cast(attrs, [:point, :team_match_information_id, :category_id])
    |> foreign_key_constraint(:team_match_information_id)
    |> foreign_key_constraint(:category_id)
  end
end
