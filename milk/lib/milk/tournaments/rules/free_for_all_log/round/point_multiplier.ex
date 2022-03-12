defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.PointMultiplier do
  @moduledoc """
  ポイントカテゴリのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.MatchInformation
  alias Milk.Tournaments.Rules.FreeForAllLog.PointMultiplierCategory, as: Category

  schema "tournaments_rules_freeforallog_round_pointmultipliers" do
    field :point, :integer

    belongs_to :match_information, MatchInformation
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(multiplier, attrs) do
    multiplier
    |> cast(attrs, [:point, :match_information_id, :category_id])
    |> foreign_key_constraint(:match_information_id)
    |> foreign_key_constraint(:category_id)
  end
end
