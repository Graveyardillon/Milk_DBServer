defmodule Milk.Repo.Migrations.RemoveBattleRoyaleLog do
  use Ecto.Migration

  def change do
    drop table(:battle_royale_log)
  end
end
