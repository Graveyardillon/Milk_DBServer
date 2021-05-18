defmodule Milk.Repo.Migrations.DeleteStartNotificationPid do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      remove :start_notification_pid
    end
  end
end
