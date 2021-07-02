defmodule Milk.Repo.Migrations.CreateTeamMembersTable do
  use Ecto.Migration

  def change do
    create table(:team_members) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all)
      add :is_leader, :boolean, default: false

      timestamps()
    end
  end
end
