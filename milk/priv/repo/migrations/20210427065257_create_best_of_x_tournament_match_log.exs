defmodule Milk.Repo.Migrations.CreateBestOfXTournamentMatchLog do
  use Ecto.Migration

  def change do
    create table(:best_of_x_tournament_match_log) do
      add :tournament_id, :integer
      add :winner_id, :integer
      add :loser_id, :integer
      add :winner_score, :integer
      add :loser_score, :integer
      add :match_list_str, :text

      timestamps()
    end
  end
end
