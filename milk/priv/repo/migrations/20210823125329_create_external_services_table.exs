defmodule Milk.Repo.Migrations.CreateExternalServicesTable do
  use Ecto.Migration

  def change do
    create table(:external_services) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :name, :string, null: false
      add :content, :string, null: false

      timestamps()
    end
  end
end
