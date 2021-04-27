defmodule Milk.TournamentProgress.BattleRoyaleLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "battle_royale_logs" do
    field :tournament_id, :integer
    field :loser_id, :integer
    field :rank, :integer

    timestamps()
  end

  @doc false
  def changeset(battle_royale_log, attrs) do
    battle_royale_log
    |> cast(attrs, [:tournament_id, :loser_id, :rank])
    |> validate_required([:tournament_id, :loser_id, :rank])
  end
end
