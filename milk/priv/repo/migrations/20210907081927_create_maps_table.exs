defmodule Milk.Repo.Migrations.CreateMapsTable do
  use Ecto.Migration

  def change do
    create table(:maps) do
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :state, :string, default: "not_selected"
      add :name, :string
      add :icon_path, :string

      timestamps()
    end
  end
end
