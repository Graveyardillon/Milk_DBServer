defmodule Milk.Repo.Migrations.AlterBestOfTournamentMatchLog do
  use Ecto.Migration

  def change do
    alter table(:best_of_x_tournament_match_log) do
      remove :match_list_str
      add :match_index, :integer
    end
  end
end
