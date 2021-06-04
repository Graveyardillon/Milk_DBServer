defmodule Milk.Repo.Migrations.AlterChatRoomAuthority do
  use Ecto.Migration

  def change do
    alter table(:chat_rooms) do
      add :authority, :integer, default: 0
    end
  end
end
