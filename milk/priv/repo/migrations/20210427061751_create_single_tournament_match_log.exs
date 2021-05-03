defmodule Milk.Repo.Migrations.CreateSingleTournamentMatchLog do
  use Ecto.Migration

  def change do
    create table(:single_tournament_match_log) do
      add :tournament_id, :integer
      add :winner_id, :integer
      add :loser_id, :integer
      add :match_list_str, :text

      timestamps()
    end
  end
end
