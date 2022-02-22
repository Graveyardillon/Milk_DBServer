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

  @type t :: %__MODULE__{
    current_round_index: :integer,
    current_match_index: :integer,
    tournament_id: :integer,
    team_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_teamstatus" do
    field :current_round_index, :integer, default: 0
    field :current_match_index, :integer, default: 0

    belongs_to :tournament, Tournament
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:current_round_index, :current_match_index, :tournament_id, :team_id])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:team_id)
  end
end
