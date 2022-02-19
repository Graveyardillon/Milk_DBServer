defmodule Milk.Repo.Migrations.RulesFreeforallRoundInformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_information) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :table_id, references(:tournaments_rules_freeforall_status, on_delete: :delete_all)

      timestamps()
    end
  end
end
