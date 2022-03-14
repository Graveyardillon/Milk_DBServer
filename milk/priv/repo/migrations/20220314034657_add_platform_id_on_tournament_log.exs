defmodule Milk.Repo.Migrations.AddPlatformIdOnTournamentLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :platform_id, references(:platforms, on_delete: :nothing)
    end
  end
end
