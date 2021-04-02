defmodule Milk.Repo.Migrations.CreateEntrant do
  use Ecto.Migration

  def change do
    create table(:entrant) do
      add :rank, :integer, default: 0
      add :tournament_id, references(:tournament, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:entrant, [:tournament_id])
    create index(:entrant, [:user_id])
  end
end
