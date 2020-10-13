defmodule Milk.Repo.Migrations.CreateTournamentUserTopicLog do
  use Ecto.Migration

  def change do
    create table(:tournament_user_topic_log) do
      add :topic_name, :string
      add :tournament_id, references(:tournament, on_delete: :delete_all)
      add :chat_room_id, references(:chat_room, on_delete: :delete_all)
      add :is_deleted, :boolean, default: false

      timestamps()
    end

  end
end
