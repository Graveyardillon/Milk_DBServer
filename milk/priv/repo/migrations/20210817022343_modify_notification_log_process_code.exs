defmodule Milk.Repo.Migrations.ModifyNotificationLogProcessCode do
  use Ecto.Migration

  def change do
    alter table("notifications_log") do
      remove :process_code
      add :process_id, :string, default: ""
    end
  end
end
