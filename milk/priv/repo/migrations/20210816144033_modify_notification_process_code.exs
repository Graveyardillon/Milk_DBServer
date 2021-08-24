defmodule Milk.Repo.Migrations.ModifyNotificationProcessCode do
  use Ecto.Migration

  def change do
    alter table("notifications") do
      remove :process_code
      add :process_id, :string, default: ""
    end
  end
end
