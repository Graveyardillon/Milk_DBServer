defmodule Milk.Repo.Migrations.DropMultipleSelectionTable do
  use Ecto.Migration

  def change do
    drop table(:multiple_selections)
  end
end
