defmodule Milk.Tournaments.Entrant do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  schema "entrant" do
    field :rank, :integer, default: 0
    # field :tournament_id, :id
    belongs_to :tournament, Tournament
    # field :user_id, :id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(entrant, attrs) do
    entrant
    |> cast(attrs, [:rank])
    # |> validate_required([:rank])
  end
end
