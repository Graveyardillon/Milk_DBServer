defmodule Milk.Repo.Migrations.RulesFreeforallRoundTable do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_table) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :name, :string

      timestamps()
    end
  end
end
