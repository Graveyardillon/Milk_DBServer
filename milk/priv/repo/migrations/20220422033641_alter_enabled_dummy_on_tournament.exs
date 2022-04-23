defmodule Milk.Repo.Migrations.AlterEnabledDummyOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :enabled_dummy, :boolean, default: false
    end
  end
end
