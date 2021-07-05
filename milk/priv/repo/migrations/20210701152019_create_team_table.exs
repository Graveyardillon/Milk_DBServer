defmodule Milk.Repo.Migrations.CreateTeamTable do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string
      add :size, :integer
      add :tournament_id, references(:tournaments, on_delete: :delete_all)
      add :icon_path, :string

      timestamps()
    end
  end
end
