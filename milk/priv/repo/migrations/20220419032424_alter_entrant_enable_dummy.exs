defmodule Milk.Repo.Migrations.AlterEntrantEnableDummy do
  use Ecto.Migration

  def change do
    alter table(:entrants) do
      add :is_dummy, :boolean, default: false
      add :name, :string
      add :icon_path, :string
    end
  end
end
