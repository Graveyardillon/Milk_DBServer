defmodule Milk.Repo.Migrations.CreateTournamentUserTopics do
  use Ecto.Migration

  def change do
    create table(:tournament_chat_topics) do
      add :topic_name, :string
      add :tournament_id, references(:tournament, on_delete: :delete_all)

      timestamps()
    end
  end
end
