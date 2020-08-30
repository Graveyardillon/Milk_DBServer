defmodule Milk.Repo.Migrations.CreateTournamentUserTopics do
  use Ecto.Migration

  def change do
    create table(:tournament_user_topics) do
      add :topic_name, :string

      timestamps()
    end

  end
end
