defmodule Milk.Repo.Migrations.CreateAppleUserTable do
  use Ecto.Migration

  def change do
    create table(:apple_users) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :apple_id, :string

      timestamps()
    end

    create unique_index(:apple_users, [:user_id])
  end
end
