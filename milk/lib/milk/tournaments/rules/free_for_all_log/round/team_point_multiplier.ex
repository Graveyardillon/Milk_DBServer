defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.TeamPointMultiplier do
  @moduledoc """
  キルポイントとかのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.TeamMatchInformation
  alias Milk.Tournaments.Rules.FreeForAllLog.PointMultiplierCategory, as: Category

  schema "tournaments_rules_freeforalllog_round_teampointmultipliers" do
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
