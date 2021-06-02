defmodule Milk.Repo.Migrations.AlterTournamentChatTopicsLog do
  use Ecto.Migration

  def change do
    alter table(:tournament_chat_topics_log) do
      remove :tournament_id
      remove :chat_room_id
      add :tab_index, :integer
    end
  end
end
