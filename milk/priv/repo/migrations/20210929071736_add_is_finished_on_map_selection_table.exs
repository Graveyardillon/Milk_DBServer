defmodule Milk.Repo.Migrations.AddIsFinishedOnMapSelectionTable do
  use Ecto.Migration

  def change do
    alter table(:map_selections) do
      add :is_finished, :boolean, default: false
    end
  end
end
