defmodule Milk.Repo.Migrations.UniqueIndexOnDiscordUsersTable do
  use Ecto.Migration

  def change do
    drop table(:discord_user)

    create table(:discord_users) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :discord_id, :string

      timestamps()
    end

    create unique_index(:discord_users, [:user_id])
  end
end
