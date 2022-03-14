defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundMatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_matchinformation) do
      add :score, :integer
      add :round_id, references(:tournaments_rules_freeforalllog_round_information, on_delete: :delete_all)

      timestamps()
    end
  end
end
