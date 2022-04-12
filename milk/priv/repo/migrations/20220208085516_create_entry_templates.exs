defmodule Milk.Repo.Migrations.CreateEntryTemplates do
  use Ecto.Migration

  def change do
    create table(:entry_templates) do
      add :title, :string
      add :tournament_id, references(:tournaments, on_delete: :nothing)

      timestamps()
    end

    create index(:entry_templates, [:tournament_id])
  end
end
