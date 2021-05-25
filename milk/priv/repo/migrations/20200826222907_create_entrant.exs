defmodule Milk.Repo.Migrations.CreateEntrant do
  use Ecto.Migration

  def change do
    create table(:entrants) do
      add :rank, :integer, default: 0
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:entrants, [:tournament_id])
    create index(:entrants, [:user_id])
  end
end
