defmodule Milk.Tournaments.TeamMember do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Team

  @type t :: %__MODULE__{
    is_invitation_confirmed: boolean(),
    is_leader: boolean(),
    user_id: integer(),
    team_id: integer()
  }

  schema "team_members" do
    field :is_invitation_confirmed, :boolean, default: false
    field :is_leader, :boolean, default: false

    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:is_leader, :is_invitation_confirmed, :user_id, :team_id])
    |> validate_required([:is_leader, :is_invitation_confirmed, :user_id, :team_id])
  end
end
