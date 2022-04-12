defmodule Milk.Repo.Migrations.DeleteTournamentType do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      remove :type
    end
  end
end
