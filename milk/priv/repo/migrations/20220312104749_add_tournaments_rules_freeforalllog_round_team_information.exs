defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundTeamInformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_team_information) do
      add :table_id, references(:tournaments_rules_freeforalllog_round_table, on_delete: :delete_all)
      add :team_id, :integer

      timestamps()
    end
  end
end
