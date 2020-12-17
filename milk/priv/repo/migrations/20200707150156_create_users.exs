defmodule Milk.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :id_for_show, :integer, null: false
      add :icon_path, :text
      add :point, :integer
      add :notification_number, :integer, default: 0
      add :logout_fl, :boolean, default: false, null: false
      add :language, :string
      add :win_count, :integer, default: 0
      add :bio, :string, null: true

      timestamps()
    end

    create unique_index(:users, [:id_for_show])
    create unique_index(:users, [:name])
  end
end
