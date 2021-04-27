defmodule Milk.TournamentProgress.BestOfXTournamentMatchLog do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Tournament

  schema "best_of_x_tournament_match_logs" do
    belongs_to :tournament, Tournament
    belongs_to :winner, User
    belongs_to :loser, User

    field :winner_score, :integer
    field :loser_score, :integer
    field :match_list_str, :string

    timestamps()
  end

  @doc false
  def changeset(best_of_x_tournament_match_log, attrs) do
    best_of_x_tournament_match_log
    |> cast(attrs, [:winner_score, :loser_score, :match_list_str])
    |> validate_required([:tournament_id, :winner_id, :loser_id, :winner_score, :loser_score, :match_list_str])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:winner_id)
    |> foreign_key_constraint(:loser_id)
  end
end
