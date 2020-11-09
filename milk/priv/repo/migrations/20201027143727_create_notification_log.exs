defmodule Milk.Repo.Migrations.CreateNotificationLog do
  use Ecto.Migration

  def change do
    create table(:notification_log) do
      add :user_id, :integer
      add :content, :string
      add :process_code, :integer
      add :data, :string

      timestamps()
    end

  end
end
