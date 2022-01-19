defmodule Milk.Repo.Migrations.CreateTournamentTags do
  use Ecto.Migration

  def change do
    create table(:tournament_tags) do
      add :name, :string

      timestamps()
    end

  end
end
