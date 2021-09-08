defmodule Milk.Repo.Migrations.CreateSelectableMapsTable do
  use Ecto.Migration

  def change do
    create table(:map_selections) do
      add :map_id, references(:maps, on_delete: :delete_all)
      add :state, :string, default: "not_selected"

      timestamps()
    end
  end
end
