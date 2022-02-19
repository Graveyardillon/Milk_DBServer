defmodule Milk.Tournaments.Rules.FreeForAll.Round.TeamInformation do
  @moduledoc """
  チーム
  """
  use Milk.Schema

  alias Milk.Tournaments.Rules.FreeForAll.Round.Table
  alias Milk.Tournaments.Team

  schema "tournaments_rules_freeforall_round_table" do
    belongs_to :table, Table
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(attrs, information) do
    information
    |> cast(attrs, [:table_id, :team_id])
    |> foreign_key_constraint(:table_id)
    |> foreign_key_constraint(:team_id)
  end
end
