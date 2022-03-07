defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundMemberpointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_memberpointmultipliers) do
      add :category_id, references(:tournaments_rules_freeforall_pointmultipliercategories, on_delete: :delete_all)
      add :point, :integer
      add :member_match_information_id, references(:tournaments_rules_freeforall_round_membermatchinformation, on_delete: :delete_all)

      timestamps()
    end
  end
end
