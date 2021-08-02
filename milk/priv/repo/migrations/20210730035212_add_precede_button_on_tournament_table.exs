defmodule Milk.Repo.Migrations.AddPrecedeButtonOnTournamentTable do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :enabled_coin_toss, :boolean, default: false
    end
  end
end
