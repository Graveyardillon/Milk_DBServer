defmodule Milk.Repo.Migrations.CreateChatMember do
  use Ecto.Migration

  def change do
    create table(:chat_members) do
      add :authority, :integer, default: 0
      add :chat_room_id, references(:chat_rooms, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:chat_members, [:chat_room_id])
    create index(:chat_members, [:user_id])
    create unique_index(:chat_members, [:user_id, :chat_room_id])
  end
end
