defmodule Milk.Repo.Migrations.UniqueUserIdAndTournamentId do
  use Ecto.Migration

  def change do
    create unique_index(:entrants, [:user_id, :tournament_id])
  end
end
