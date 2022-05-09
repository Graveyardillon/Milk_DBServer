defmodule Milk.Repo.Migrations.AddBracketsLogTable do
  use Ecto.Migration

  def change do
    create table(:brackets_log) do
      add :name, :string
      add :owner_id, references(:users, on_delete: :nothing)
      add :bracket_id, :integer
      add :url, :string
      add :enabled_bronze_medal_match, :boolean, default: false

      timestamps()
    end

    create unique_index(:brackets_log, [:url])
  end
end
