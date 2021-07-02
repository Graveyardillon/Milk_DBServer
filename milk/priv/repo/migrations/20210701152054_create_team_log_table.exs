defmodule Milk.Repo.Migrations.CreateTeamLogTable do
  use Ecto.Migration

  def change do
    create table(:team_log) do
      add :name, :string
      add :size, :integer
      add :tournament_id, :integer

      timestamps()
    end
  end
end
