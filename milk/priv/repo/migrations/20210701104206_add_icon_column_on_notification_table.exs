defmodule Milk.Repo.Migrations.AddIconColumnOnNotificationTable do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :icon_path, :text
    end
  end
end
