defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforalllogPointmultipliercategories do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_pointmultipliercategories) do
      add :name, :string
      add :multiplier, :float
      add :tournament_id, references(:tournaments_log, on_delete: :delete_all)

      timestamps()
    end
  end
end
