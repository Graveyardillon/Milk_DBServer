defmodule Milk.Repo.Migrations.CreateServiceIdsTable do
  use Ecto.Migration

  def change do
    create table(:service_references) do
      add :twitter_id, :string, null: true
      add :riot_id, :string, null: true
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
