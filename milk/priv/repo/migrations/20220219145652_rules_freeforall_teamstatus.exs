defmodule Milk.Repo.Migrations.RulesFreeforallTeamstatus do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_teamstatus) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all)
      add :current_round_index, :integer, default: 0
      add :current_match_index, :integer, default: 0

      timestamps()
    end
  end
end
