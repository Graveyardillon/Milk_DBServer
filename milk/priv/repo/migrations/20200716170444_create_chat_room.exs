defmodule Milk.Repo.Migrations.CreateChatRoom do
  use Ecto.Migration

  def change do
    create table(:chat_rooms) do
      add :name, :string
      add :last_chat, :text, default: nil
      add :count, :integer, default: 0
      add :member_count, :integer, default: 0
      add :is_private, :boolean, default: false
      timestamps()
    end

  end
end
