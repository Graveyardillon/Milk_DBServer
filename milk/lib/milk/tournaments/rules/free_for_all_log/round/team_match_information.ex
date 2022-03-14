defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.TeamMatchInformation do
  @moduledoc """
  match infoのログ（チーム）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.TeamInformation
  alias Milk.Tournaments.Rules.FreeForAllLog.Round.TeamPointMultiplier

  schema "tournaments_rules_freeforalllog_round_teammatchinformation" do
    field :score, :integer
    belongs_to :round, TeamInformation

    has_many :point_multipliers, TeamPointMultiplier

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end
