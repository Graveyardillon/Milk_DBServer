defmodule Milk.Repo.Migrations.CreateAuth do
  use Ecto.Migration

  def change do
    create table(:auth) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :password, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:auth, [:user_id])
    create unique_index(:auth, [:email])
  end
end
