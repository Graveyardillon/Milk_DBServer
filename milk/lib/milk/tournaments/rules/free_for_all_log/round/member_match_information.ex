defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.MemberMatchInformation do
  @moduledoc """
  member match information ログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.TeamMatchInformation

  schema "tournaments_rules_freeforalllog_round_membermatchinformation" do
    field :score, :integer
    field :user_id, :integer

    belongs_to :team_match_information, TeamMatchInformation

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :user_id, :team_match_information_id])
    |> foreign_key_constraint(:team_match_information_id)
  end
end
