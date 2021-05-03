defmodule Milk.Repo.Migrations.CreateAssistant do
  use Ecto.Migration

  def change do
    create table(:assistants) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:assistants, [:tournament_id])
    create index(:assistants, [:user_id])
  end
end
