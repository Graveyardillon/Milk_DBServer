defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallRoundTeampointmultipliers do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_round_teampointmultipliers) do
      add :category_id, references(:tournaments_rules_freeforall_pointmultipliercategories, on_delete: :delete_all)
      add :point, :integer
      add :team_match_information_id, references(:tournaments_rules_freeforall_round_teammatchinformation, on_delete: :delete_all)

      timestamps()
    end
  end
end
