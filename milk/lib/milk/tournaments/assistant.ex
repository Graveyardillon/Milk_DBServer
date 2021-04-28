defmodule Milk.Tournaments.Assistant do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  schema "assistant" do
    belongs_to :tournament, Tournament
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(assistant, attrs) do
    assistant
    |> cast(attrs, [])
  end
end
