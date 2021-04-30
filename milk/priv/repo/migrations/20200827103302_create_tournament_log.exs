defmodule Milk.Repo.Migrations.CreateTournamentLog do
  use Ecto.Migration

  def change do
    create table(:tournaments_log) do
      add :name, :string
      add :event_date, :timestamptz
      add :capacity, :integer
      add :description, :text
      add :deadline, :timestamptz
      add :type, :integer
      add :url, :string
      add :tournament_id, :integer
      add :game_id, :integer
      add :master_id, :integer
      add :winner_id, :integer
      add :is_deleted, :boolean, default: false
      add :is_started, :boolean, default: false

      timestamps()
    end
  end
end
