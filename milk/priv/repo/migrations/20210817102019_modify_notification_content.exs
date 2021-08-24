defmodule Milk.Repo.Migrations.ModifyNotificationContent do
  use Ecto.Migration

  def change do
    alter table("notifications") do
      remove :content
      add :title, :string
      add :body_text, :string
    end
    alter table("notifications_log") do
      remove :content
      add :title, :string
      add :body_text, :string
    end
  end
end
