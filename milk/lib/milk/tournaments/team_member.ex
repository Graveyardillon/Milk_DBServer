defmodule Milk.Tournaments.TeamMember do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Tournaments.Team

  schema "team_members" do
    belongs_to :user, User
    belongs_to :team, Team
    field :is_leader, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:is_leader, :user_id, :team_id])
  end
end
