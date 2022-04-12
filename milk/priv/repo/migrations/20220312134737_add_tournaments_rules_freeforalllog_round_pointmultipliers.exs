defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundPointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforallog_round_pointmultipliers) do
      add :point, :integer
      add :match_information_id, references(:tournaments_rules_freeforalllog_round_matchinformation, on_delete: :delete_all)
      add :category_id, references(:tournaments_rules_freeforalllog_pointmultipliercategories, on_delete: :delete_all)

      timestamps()
    end
  end
end
