defmodule Milk.Repo.Migrations.AlterTournamentTableOfTeam do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :is_team, :boolean, default: false
    end
  end
end
