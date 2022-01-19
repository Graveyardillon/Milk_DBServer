defmodule Milk.Repo.Migrations.CreateTournamentTagRelations do
  use Ecto.Migration

  def change do
    create table(:tournament_tag_relations, primary_key: false) do
      add :tag_id, references(:tournament_tags, on_delete: :delete_all)
      add :tournament_id, references(:tournaments, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:tournament_tag_relations, [:tag_id, :tournament_id])
  end
end
