defmodule Milk.Repo.Migrations.CreateEntrantLog do
  use Ecto.Migration

  def change do
    create table(:entrant_log) do
      add :entrant_id, :integer
      add :tournament_id, :integer
      add :user_id, :integer
      add :rank, :integer
      add :is_deleted, :boolean, default: false

      timestamps()
    end

  end
end
