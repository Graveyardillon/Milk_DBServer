defmodule Milk.Repo.Migrations.CreateRelations do
  use Ecto.Migration

  def change do
    create table(:relations) do
      add :followee_id, references(:users, on_delete: :delete_all)
      add :follower_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

  end
end
