defmodule Milk.Repo.Migrations.AddBronzeMatchScoresOnBracket do
  use Ecto.Migration

  def change do
    alter table(:brackets) do
      add :bronze_match_winner_score, :integer
      add :bronze_match_loser_score, :integer
    end
  end
end
