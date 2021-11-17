defmodule Milk.Tournaments.Progress.BestOfXTournamentMatchLog do
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    loser_id: integer(),
    loser_score: integer(),
    match_index: integer(),
    tournament_id: integer(),
    winner_id: integer(),
    winner_score: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "best_of_x_tournament_match_log" do
    field :loser_id, :integer
    field :loser_score, :integer
    field :match_index, :integer
    field :tournament_id, :integer
    field :winner_id, :integer
    field :winner_score, :integer

    timestamps()
  end

  @doc false
  def changeset(best_of_x_tournament_match_log, attrs) do
    best_of_x_tournament_match_log
    |> cast(attrs, [
      :tournament_id,
      :winner_id,
      :loser_id,
      :winner_score,
      :loser_score,
      :match_index
    ])
    |> validate_required([
      :tournament_id,
      :winner_id,
      :loser_id,
      :winner_score,
      :loser_score,
      :match_index
    ])
  end
end
