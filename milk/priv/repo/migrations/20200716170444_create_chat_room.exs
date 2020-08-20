defmodule Milk.Repo.Migrations.CreateChatRoom do
  use Ecto.Migration

  def change do
    create table(:chat_room) do
      add :name, :string
      add :last_chat, :text, default: nil
      add :count, :integer, default: 0
      add :update_time, :timestamptz
      add :member_count, :integer, default: 0
      timestamps(updated_at: false)
    end

  end
end
