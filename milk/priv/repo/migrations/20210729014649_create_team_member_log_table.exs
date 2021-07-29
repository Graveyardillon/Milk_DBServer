defmodule Milk.Repo.Migrations.CreateTeamMemberLogTable do
  use Ecto.Migration

  def change do
    create table(:team_member_log) do
      add :user_id, :integer
      add :team_id, :integer
      add :is_leader, :boolean
      add :is_invitation_confirmed, :boolean

      timestamps()
    end
  end
end
