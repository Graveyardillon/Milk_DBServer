defmodule Milk.Tournaments.TeamInvitation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.TeamMember

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
  end
end
