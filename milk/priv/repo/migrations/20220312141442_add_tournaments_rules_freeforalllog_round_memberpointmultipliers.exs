defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundMemberpointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_memberpointmultipliers) do
      add :point, :integer
      add :member_match_information_id, references(:tournaments_rules_freeforalllog_round_membermatchinformation, on_delete: :delete_all)
      add :category_id, references(:tournaments_rules_freeforalllog_pointmultipliercategories, on_delete: :delete_all)

      timestamps()
    end
  end
end
