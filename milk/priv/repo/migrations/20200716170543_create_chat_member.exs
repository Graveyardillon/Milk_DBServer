defmodule Milk.Repo.Migrations.CreateChatMember do
  use Ecto.Migration

  def change do
    create table(:chat_member) do
      add :authority, :integer
      add :chat_room_id, references(:chat_room, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:chat_member, [:chat_room_id])
    create index(:chat_member, [:user_id])
    create unique_index(:chat_member, [:user_id, :chat_room_id])
  end
end
