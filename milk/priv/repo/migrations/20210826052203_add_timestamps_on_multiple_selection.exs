defmodule Milk.Repo.Migrations.AddTimestampsOnMultipleSelection do
  use Ecto.Migration

  def change do
    alter table(:multiple_selections) do
      timestamps()
    end
  end
end
