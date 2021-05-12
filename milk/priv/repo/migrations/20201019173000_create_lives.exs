defmodule Milk.Repo.Migrations.CreateLives do
  use Ecto.Migration

  def change do
    create table(:lives) do
      add :name, :string
      add :number_of_viewers, :integer, default: 0
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :streamer_id, references(:users, on_delete: :delete_all)
      add :thumbnail_path, :string
      add :url, :string

      timestamps()
    end
  end
end
