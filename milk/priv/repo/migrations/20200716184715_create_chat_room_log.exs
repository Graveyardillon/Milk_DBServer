defmodule Milk.Repo.Migrations.CreateChatRoomLog do
  use Ecto.Migration

  def change do
    create table(:chat_room_log, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string
      add :last_chat, :text
      add :count, :integer
      add :create_time, :timestamptz
      add :update_time, :timestamptz
      add :member_count, :integer
      add :is_private, :boolean
    end

  end
end
