defmodule Milk.TournamentProgress.BattleRoyaleLog do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.Yser
  alias Milk.Tournaments.Tournament

  schema "battle_royale_logs" do
    belongs_to :tournament, Tournament
    belongs_to :loser, User

    field :rank, :integer

    timestamps()
  end

  @doc false
  def changeset(battle_royale_log, attrs) do
    battle_royale_log
    |> cast(attrs, [:rank])
    |> validate_required([:tournament_id, :loser_id, :rank])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:loser_id)
  end
end
