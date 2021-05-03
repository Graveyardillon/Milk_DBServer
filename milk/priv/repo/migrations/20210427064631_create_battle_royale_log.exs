defmodule Milk.Repo.Migrations.CreateBattleRoyaleLog do
  use Ecto.Migration

  def change do
    create table(:battle_royale_log) do
      add :tournament_id, :integer
      add :loser_id, :integer
      add :rank, :integer

      timestamps()
    end
  end
end
