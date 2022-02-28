defmodule Milk.Repo.Migrations.RulesFreeforallRoundMatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_matchinformation) do
      add :round_id, references(:tournaments_rules_freeforall_round_information, on_delete: :delete_all)
      add :score, :integer

      timestamps()
    end
  end
end
