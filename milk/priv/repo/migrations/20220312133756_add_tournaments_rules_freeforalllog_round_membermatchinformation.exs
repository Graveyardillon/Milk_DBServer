defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundMembermatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_membermatchinformation) do
      add :score, :integer
      add :team_match_information_id, references(:tournaments_rules_freeforalllog_round_teammatchinformation, on_delete: :delete_all)
      add :user_id, :integer

      timestamps()
    end
  end
end
