defmodule Milk.Tournaments.Entrant do
  use Milk.Schema

  import Ecto.Changeset
  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  schema "entrants" do
    field :rank, :integer, default: 0
    belongs_to :tournament, Tournament
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(entrant, attrs) do
    entrant
    |> cast(attrs, [:rank])
    |> unique_constraint([:user_id,:tournament_id], name: :entrants_user_id_tournament_id_index)
  end
end
