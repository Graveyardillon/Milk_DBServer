defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundMembermatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_membermatchinformation) do
      add :team_match_information_id, references(:tournaments_rules_freeforall_round_teammatchinformation, on_delete: :delete_all)
      add :score, :integer
      add :user_id, references(:users)

      timestamps()
    end
  end
end
