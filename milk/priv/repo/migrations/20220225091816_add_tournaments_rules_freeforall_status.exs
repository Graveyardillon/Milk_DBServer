defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallStatus do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_status) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :current_round_index, :integer, default: 0

      timestamps()
    end
  end
end
