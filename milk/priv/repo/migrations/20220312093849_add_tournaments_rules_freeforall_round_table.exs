defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundTable do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_table) do
      add :name, :string
      add :round_index, :integer
      add :current_match_index, :integer, default: 0
      add :is_finished, :boolean, default: false
      add :tournament_id, references(:tournaments_log, on_delete: :delete_all)

      timestamps()
    end
  end
end
