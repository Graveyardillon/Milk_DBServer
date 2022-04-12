defmodule Milk.Repo.Migrations.AddIsCuttingOfMode do
  use Ecto.Migration

  def change do
    alter table(:tournaments_rules_freeforall_information) do
      add :is_truncation_enabled, :boolean, default: false
    end
  end
end
