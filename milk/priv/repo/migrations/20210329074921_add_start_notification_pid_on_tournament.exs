defmodule Milk.Repo.Migrations.AddStartNotificationPidOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :start_notification_pid, :string, default: nil
    end
  end
end
