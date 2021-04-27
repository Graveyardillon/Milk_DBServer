defmodule Milk.Repo.Migrations.CreateSingleTournamentMatchLog do
  use Ecto.Migration

  def change do
    create table(:single_tournament_match_logs) do
      add :tournament_id, references(:tournament, on_delete: :nothing)
      add :winner_id, references(:users, on_delete: :nothing)
      add :loser_id, references(:users, on_delete: :nothing)
      add :match_list_str, :text

      timestamps()
    end
  end
end
