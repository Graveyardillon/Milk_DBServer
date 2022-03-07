defmodule Milk.Repo.Migrations.AddTournamentsRulesFreeforallPointmultipliercategories do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforall_pointmultipliercategories) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :name, :string
      add :multiplier, :float

      timestamps()
    end
  end
end
