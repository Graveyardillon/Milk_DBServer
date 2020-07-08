defmodule Milk.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :icon_path, :text
      add :point, :integer
      add :notification_number, :integer
      add :logout_fl, :boolean, default: false, null: false
      add :language, :string

      timestamps()
    end

  end
end
