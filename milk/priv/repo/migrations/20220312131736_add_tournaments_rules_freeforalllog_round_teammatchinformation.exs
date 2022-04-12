defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundTeammatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_teammatchinformation) do
      add :score, :integer
      add :round_id, references(:tournaments_rules_freeforalllog_round_team_information, on_delete: :delete_all)

      timestamps()
    end
  end
end
