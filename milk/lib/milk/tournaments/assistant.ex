defmodule Milk.Tournaments.Assistant do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  @type t :: %__MODULE__{
    tournament_id: integer(),
    user_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "assistants" do
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
