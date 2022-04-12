defmodule Milk.Repo.Migrations.CreateDiscordUsersTable do
  use Ecto.Migration

  def change do
    create table(:discord_user) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :discord_id, :string

      timestamps()
    end

    create index(:discord_user, [:user_id])
  end
end
