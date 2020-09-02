defmodule Milk.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :id_for_show, :integer
      add :icon_path, :text
      add :point, :integer
      add :notification_number, :integer
      add :logout_fl, :boolean, default: false, null: false
      add :language, :string
      add :bio, :string

      timestamps()
    end

    create unique_index(:users, [:id_for_show])
  end
end
