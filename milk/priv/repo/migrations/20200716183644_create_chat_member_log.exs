defmodule Milk.Repo.Migrations.CreateChatMemberLog do
  use Ecto.Migration

  def change do
    create table(:chat_member_log) do
      add :chat_room_id, :integer
      add :user_id, :integer
      add :authority, :integer
      add :create_time, :timestamptz
      add :update_time, :timestamptz
      add :is_deleted, :boolean, default: false
    end

  end
end
