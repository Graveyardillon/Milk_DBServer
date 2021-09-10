defmodule Milk.Repo.Migrations.AlterSelectableMapsTable do
  use Ecto.Migration

  def change do
    alter table(:map_selections) do
      add :small_id, :integer
      add :large_id, :integer
    end
  end
end
