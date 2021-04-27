defmodule Milk.TournamentProgress.SingleTournamentMatchLog do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Tournament

  schema "single_tournament_match_logs" do
    belongs_to :tournament, Tournament
    belongs_to :winner, User
    belongs_to :loser, User

    field :match_list_str, :string

    timestamps()
  end

  @doc false
  def changeset(single_tournament_match_log, attrs) do
    single_tournament_match_log
    |> cast(attrs, [:tournament_id, :winner_id, :loser_id, :match_list_str])
    |> validate_required([:tournament_id, :winner_id, :loser_id, :match_list_str])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:winner_id)
    |> foreign_key_constraint(:loser_id)
  end
end
