defmodule Milk.Repo.Migrations.AddIconPathOnMultipleSelection do
  use Ecto.Migration

  def change do
    alter table(:multiple_selections) do
      add :icon_path, :string
    end
  end
end
