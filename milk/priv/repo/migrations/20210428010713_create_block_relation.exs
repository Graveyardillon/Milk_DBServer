defmodule Milk.Repo.Migrations.CreateBlockRelation do
  use Ecto.Migration

  def change do
    create table(:block_relations) do
      add :blocked_user_id, references(:users, on_delete: :delete_all)
      add :block_user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
