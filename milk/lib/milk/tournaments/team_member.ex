defmodule Milk.Tournaments.TeamMember do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Team

  schema "team_members" do
    belongs_to :user, User
    belongs_to :team, Team

    field :is_leader, :boolean, default: false
    field :is_invitation_confirmed, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:is_leader, :is_invitation_confirmed, :user_id, :team_id])
  end
end
