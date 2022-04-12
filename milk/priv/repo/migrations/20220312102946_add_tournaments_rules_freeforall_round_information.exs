defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundInformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_information) do
      add :table_id, references(:tournaments_rules_freeforalllog_round_table, on_delete: :delete_all)
      add :user_id, :integer

      timestamps()
    end
  end
end
