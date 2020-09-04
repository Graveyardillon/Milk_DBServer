defmodule Milk.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :title, :string, null: false
      add :icon_path, :string

      timestamps()
    end

  end
end