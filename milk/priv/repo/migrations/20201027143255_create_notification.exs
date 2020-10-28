defmodule Milk.Repo.Migrations.CreateNotification do
  use Ecto.Migration

  def change do
    create table(:notification) do
      add :content, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:notification, [:user_id])
  end
end
