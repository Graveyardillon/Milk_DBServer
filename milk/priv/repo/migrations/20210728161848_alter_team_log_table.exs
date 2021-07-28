defmodule Milk.Repo.Migrations.AlterTeamLogTable do
  use Ecto.Migration

  def change do
    alter table(:team_log) do
      add :team_id, :integer
      add :icon_path, :string
      add :is_confirmed, :boolean
      add :rank, :integer
    end
  end
end
