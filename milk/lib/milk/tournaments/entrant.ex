defmodule Milk.Tournaments.Entrant do
  use Milk.Schema

  import Ecto.Changeset
  alias Milk.Repo
  alias Milk.Tournaments.Entrant
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
    |> cast(attrs, [:rank, :user_id, :tournament_id])
    |> unique_constraint_both()
  end

  defp unique_constraint_both(changeset) do
    IO.inspect(changeset, label: :changeset)
    Repo.all(Entrant)|> IO.inspect(label: :database)
    changeset
    |> unique_constraint([:user_id])
    |> IO.inspect(label: :user)
    |> case do
      {:error,_} -> unique_constraint(changeset, [:tournament_id])
      other ->
        IO.inspect(other, label: :dnjqwn)
        changeset
    end
  end
end
