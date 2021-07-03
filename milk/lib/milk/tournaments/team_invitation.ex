defmodule Milk.Tournaments.TeamInvitation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Team

  schema "team_invitations" do
    field :text, :string

    belongs_to :team, Team
    belongs_to :destination, User
    belongs_to :sender, User

    timestamps()
  end

  @doc false
  def changeset(team_invitation, attrs) do
    team_invitation
    |> cast(attrs, [:text, :team_id, :destination_id, :sender_id])
  end
end