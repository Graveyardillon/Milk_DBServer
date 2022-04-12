defmodule Milk.Repo.Migrations.RulesFreeforallRoundTeammatchinformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_teammatchinformation) do
      add :round_id, references(:tournaments_rules_freeforall_round_teaminformation, on_delete: :delete_all)
      add :score, :integer

      timestamps()
    end
  end
end
