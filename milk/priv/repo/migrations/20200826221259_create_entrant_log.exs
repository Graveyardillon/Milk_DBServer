defmodule Milk.Repo.Migrations.CreateEntrantLog do
  use Ecto.Migration

  def change do
    create table(:entrant_log) do
      add :tournament_id, :integer
      add :user_id, :integer
      add :rank, :integer

      timestamps()
    end

  end
end
