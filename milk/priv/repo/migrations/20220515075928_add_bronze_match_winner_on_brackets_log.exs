defmodule Milk.Repo.Migrations.AddBronzeMatchWinnerOnBracketsLog do
  use Ecto.Migration

  def change do
    alter table(:brackets_log) do
      add :bronze_match_winner_participant_id, :integer
    end
  end
end
