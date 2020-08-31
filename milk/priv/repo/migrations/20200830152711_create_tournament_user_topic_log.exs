defmodule Milk.Repo.Migrations.CreateTournamentUserTopicLog do
  use Ecto.Migration

  def change do
    create table(:tournament_user_topic_log) do
      add :topic_name, :string

      timestamps()
    end

  end
end
