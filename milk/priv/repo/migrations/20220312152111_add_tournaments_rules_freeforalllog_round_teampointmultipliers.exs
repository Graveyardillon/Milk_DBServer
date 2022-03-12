defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogRoundTeampointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_round_teampointmultipliers) do
      add :field, :integer
      add :team_match_information_id, references(:tournaments_rules_freeforalllog_round_teammatchinformation, on_delete: :delete_all)
      add :category_id, references(:tournaments_rules_freeforalllog_pointmultipliercategories, on_delete: :delete_all)

      timestamps()
    end
  end
end
