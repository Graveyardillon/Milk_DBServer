defmodule Milk.Tournaments.Rules.FreeForAll.TeamStatus do
  @moduledoc """
  現在のステータス（チーム）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.{
    Team,
    Tournament
  }

  schema "tournaments_rules_freeforall_teamstatus" do
    field :current_round_index, :integer, default: 0
    field :current_match_index, :integer, default: 0

    belongs_to :tournament, Tournament
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(attrs, status) do
    status
    |> cast(attrs, [:current_round_index, :current_match_index, :tournament_id, :team_id])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:team_id)
  end
end
