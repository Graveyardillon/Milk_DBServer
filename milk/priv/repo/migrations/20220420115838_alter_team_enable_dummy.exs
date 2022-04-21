defmodule Milk.Repo.Migrations.AlterTeamEnableDummy do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :is_dummy, :boolean, default: false
    end
  end
end
