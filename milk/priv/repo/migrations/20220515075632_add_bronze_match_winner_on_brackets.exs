defmodule Milk.Repo.Migrations.AddBronzeMatchWinnerOnBrackets do
  use Ecto.Migration

  def change do
    alter table(:brackets) do
      add :bronze_match_winner_participant_id, :integer
    end
  end
end
