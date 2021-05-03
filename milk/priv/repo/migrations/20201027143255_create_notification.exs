defmodule Milk.Repo.Migrations.CreateNotification do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :content, :string
      add :process_code, :integer
      add :data, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:notifications, [:user_id])
  end
end
