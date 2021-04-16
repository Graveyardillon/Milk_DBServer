defmodule Milk.Repo.Migrations.AddTournamentChatTopics do
  use Ecto.Migration

  def change do
    alter table(:tournament_chat_topics) do
      add :tab_index, :integer, null: false
    end
  end
end
