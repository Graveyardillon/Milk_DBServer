defmodule Milk.Repo.Migrations.CreateTournament do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :name, :string
      add :event_date, :timestamptz
      add :capacity, :integer
      add :description, :text
      add :deadline, :timestamptz
      add :type, :integer
      add :url, :string
      add :count, :integer
      add :game_id, references(:games, on_delete: :nothing), null: true
      add :game_name, :text
      add :master_id, references(:users, on_delete: :nothing)
      add :thumbnail_path, :text
      add :password, :text
      add :is_started, :boolean, default: false
      add :start_recruiting, :timestamptz
      add :platform_id, references(:platforms, on_delete: :nothing)

      timestamps()
    end

    create index(:tournaments, [:game_id])
    create index(:tournaments, [:master_id])
  end
end
