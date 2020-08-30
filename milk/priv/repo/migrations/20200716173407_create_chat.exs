defmodule Milk.Repo.Migrations.CreateChat do
  use Ecto.Migration

  def change do
    create table(:chat) do
      add :word, :text
      add :index, :integer
      add :chat_room_id, references(:chat_room, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :nothing)
      
      timestamps()
      
    end

    create index(:chat, [:chat_room_id])
    create index(:chat, [:user_id])
    create unique_index(:chat, [:index, :chat_room_id])
  end
end
