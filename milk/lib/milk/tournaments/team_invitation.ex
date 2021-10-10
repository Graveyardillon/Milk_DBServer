defmodule Milk.Tournaments.TeamInvitation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.TeamMember

  @type t :: %__MODULE__{
    team_member_id: integer(),
    sender_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "team_invitations" do
    # belongs_to :team, Team
    belongs_to :team_member, TeamMember
    # belongs_to :destination, User
    belongs_to :sender, User

    timestamps()
  end

  @doc false
  def changeset(team_invitation, attrs) do
    team_invitation
    |> cast(attrs, [:team_member_id, :sender_id])
    |> validate_required([:team_member_id, :sender_id])
  end
end
