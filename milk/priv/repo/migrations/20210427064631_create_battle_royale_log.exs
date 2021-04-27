defmodule Milk.Repo.Migrations.CreateBattleRoyaleLog do
  use Ecto.Migration

  def change do
    create table(:battle_royale_log) do
      add :tournament_id, references(:tournament, on_delete: :nothing)
      add :loser_id, references(:users, on_delete: :nothing)
      add :rank, :integer

      timestamps()
    end
  end
end
