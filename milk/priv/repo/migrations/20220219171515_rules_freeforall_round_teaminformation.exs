defmodule Milk.Repo.Migrations.RulesFreeforallRoundTeaminformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_teaminformation) do
      add :team_id, references(:teams, on_delete: :delete_all)
      add :table_id, references(:tournaments_rules_freeforall_status, on_delete: :delete_all)

      timestamps()
    end
  end
end
