defmodule Milk.Repo.Migrations.AlterTournamentTableOfTeamSize do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :team_size, :integer, default: nil
    end
  end
end
