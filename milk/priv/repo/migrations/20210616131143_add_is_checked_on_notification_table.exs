defmodule Milk.Repo.Migrations.AddIsCheckedOnNotificationTable do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :is_checked, :boolean, default: false
    end
  end
end
