defmodule Milk.Tournaments.Rules.FreeForAll.Round.PointMultiplier do
  @moduledoc """
  キルポイントとかのスコアを実際に記録kしておくためのやつ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.Rules.FreeForAll.Round.MatchInformation

  schema "tournaments_rules_freeforall_round_pointmultipliers" do
    field :point, :integer

    belongs_to :match_information, MatchInformation
    belongs_to :tournament, Tournament
  end

  @doc false
  def changeset(multipliers, attrs) do
    multipliers
    |> cast(attrs, [:point, :match_information_id, :tournament_id])
    |> foreign_key_constraint(:match_information_id)
    |> foreign_key_constraint(:tournament_id)
  end
end
