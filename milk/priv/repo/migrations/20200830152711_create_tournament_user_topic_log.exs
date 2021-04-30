defmodule Milk.Repo.Migrations.CreateTournamentChatTopicLog do
  use Ecto.Migration

  def change do
    create table(:tournament_chat_topics_log) do
      add :topic_name, :string
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :chat_room_id, references(:chat_rooms, on_delete: :delete_all)
      add :is_deleted, :boolean, default: false

      timestamps()
    end

  end
end
