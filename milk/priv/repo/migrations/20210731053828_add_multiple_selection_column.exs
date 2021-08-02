defmodule Milk.Repo.Migrations.AddMultipleSelectionColumn do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :enabled_multiple_selection, :boolean, default: false
    end
  end
end
