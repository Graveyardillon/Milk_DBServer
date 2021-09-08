defmodule Milk.Repo.Migrations.AlterMultipleSelections do
  use Ecto.Migration

  def change do
    alter table(:maps) do
      remove :state
    end
  end
end
