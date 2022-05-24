defmodule Milk.Repo.Migrations.AddBronzeMatchScoresOnBracketLog do
  use Ecto.Migration

  def change do
    alter table(:brackets_log) do
      add :bronze_match_winner_score, :integer
      add :bronze_match_loser_score, :integer
    end
  end
end
