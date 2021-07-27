defmodule Milk.Repo.Migrations.AlterTournamentLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :count, :integer
      add :is_team, :boolean, default: false
      add :team_size, :integer
    end
  end
end
