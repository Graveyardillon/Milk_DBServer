defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.MatchInformation do
  @moduledoc """
  matchinfoのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.Information
  alias Milk.Tournaments.Rules.FreeForAllLog.Round.PointMultiplier

  schema "tournaments_rules_freeforalllog_round_matchinformation" do
    field :score, :integer
    belongs_to :round, Information

    has_many :point_multipliers, PointMultiplier

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end
