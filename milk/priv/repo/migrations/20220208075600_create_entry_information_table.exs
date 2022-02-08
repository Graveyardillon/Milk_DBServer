defmodule Milk.Repo.Migrations.CreateEntryInformationTable do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
