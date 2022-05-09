defmodule Milk.Repo.Migrations.AddBracketsTable do
  use Ecto.Migration

  def change do
    create table(:brackets) do
      add :name, :string
      add :owner_id, references(:users, on_delete: :nothing)
      add :url, :string
      add :enabled_bronze_medal_match, :boolean, default: false

      timestamps()
    end

    create unique_index(:brackets, [:url])
  end
end
