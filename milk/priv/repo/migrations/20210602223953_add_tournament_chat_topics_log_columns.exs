defmodule Milk.Repo.Migrations.AddTournamentChatTopicsLogColumns do
  use Ecto.Migration

  def change do
    alter table(:tournament_chat_topics_log) do
      add :tournament_id, :integer
      add :chat_room_id, :integer
    end
  end
end
