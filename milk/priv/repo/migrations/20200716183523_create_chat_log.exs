defmodule Milk.Repo.Migrations.CreateChatLog do
  use Ecto.Migration

  def change do
    create table(:chat_log) do
      add :chat_room_id, :integer
      add :word, :text
      add :user_id, :integer
      add :index, :integer
      add :create_time, :timestamptz
      add :update_time, :timestamptz
      add :is_deleted, :boolean, default: false
    end

    create unique_index(:chat_log, [:index, :chat_room_id])

  end
end
