defmodule Milk.Tournaments.Progress.SingleTournamentMatchLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "single_tournament_match_log" do
    field :tournament_id, :integer
    field :winner_id, :integer
    field :loser_id, :integer

    field :match_list_str, :string

    timestamps()
  end

  @doc false
  def changeset(single_tournament_match_log, attrs) do
    single_tournament_match_log
    |> cast(attrs, [:tournament_id, :winner_id, :loser_id, :match_list_str])
    |> validate_required([:tournament_id, :winner_id, :loser_id, :match_list_str])
  end
end
