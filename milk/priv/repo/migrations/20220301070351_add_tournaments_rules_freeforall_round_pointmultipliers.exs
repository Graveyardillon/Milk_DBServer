defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundPointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_pointmultipliers) do
      add :category_id, references(:tournaments_rules_freeforall_pointmultipliercategories, on_delete: :delete_all)
      add :point, :integer
      add :match_information_id, references(:tournaments_rules_freeforall_round_matchinformation, on_delete: :delete_all)

      timestamps()
    end
  end
end
