defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.Table do
  @moduledoc """
  対戦カードのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Log.TournamentLog

  schema "tournaments_rules_freeforalllog_round_table" do
    field :name, :string
    field :round_index, :integer
    field :current_match_index, :integer, default: 0
    field :is_finished, :boolean, default: false

    belongs_to :tournament, TournamentLog

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:name, :round_index, :current_match_index, :is_finished, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end
