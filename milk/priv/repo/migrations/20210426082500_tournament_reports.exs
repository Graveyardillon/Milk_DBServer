defmodule Milk.Repo.Migrations.TournamentReports do
  use Ecto.Migration

  def change do
    create table(:tournament_reports) do
      add :report_type, :integer
      add :reporter_id, references(:users)

      add :name, :string
      add :event_date, :timestamptz
      add :capacity, :integer
      add :description, :text
      add :deadline, :timestamptz
      add :type, :integer
      add :url, :string
      add :count, :integer
      add :game_id, :integer
      add :game_name, :text
      add :master_id, references(:users, on_delete: :nothing)
      add :thumbnail_path, :text
      add :start_recruiting, :timestamptz
      add :platform_id, references(:platforms, on_delete: :nothing)

      timestamps()
    end
  end
end
