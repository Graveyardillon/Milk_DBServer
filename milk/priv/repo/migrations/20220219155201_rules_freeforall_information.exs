defmodule Milk.Repo.Migrations.RulesFreeforallInformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_information) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :round_number, :integer
      add :match_number, :integer
      add :round_capacity, :integer

      timestamps()
    end
  end
end
