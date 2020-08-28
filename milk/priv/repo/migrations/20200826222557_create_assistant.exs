defmodule Milk.Repo.Migrations.CreateAssistant do
  use Ecto.Migration

  def change do
    create table(:assistant) do
      add :tournament_id, references(:tournament, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:assistant, [:tournament_id])
    create index(:assistant, [:user_id])
  end
end
