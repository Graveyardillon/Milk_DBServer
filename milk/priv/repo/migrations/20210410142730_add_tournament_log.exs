defmodule Milk.Repo.Migrations.AddTournamentLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :game_name, :string
      add :thumbnail_path, :string
    end
  end
end
