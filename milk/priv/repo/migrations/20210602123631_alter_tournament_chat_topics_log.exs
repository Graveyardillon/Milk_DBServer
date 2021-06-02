defmodule Milk.Repo.Migrations.AlterTournamentChatTopicsLog do
  use Ecto.Migration

  def change do
    alter table(:tournament_chat_topics_log) do
      modify :tournament_id, :integer
      modify :chat_room_id, :integer
      add :tab_index, :integer
    end
  end
end
