defmodule Milk.Repo.Migrations.AlterTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :rank, :integer, default: 0
    end
  end
end
