defmodule Milk.Repo.Migrations.ModifyCreateMigration do
  use Ecto.Migration

  def change do
    drop constraint :entry_templates, "entry_templates_tournament_id_fkey"
    alter table(:entry_templates) do
      modify :tournament_id, references(:tournaments, on_delete: :delete_all)
    end
  end
end
