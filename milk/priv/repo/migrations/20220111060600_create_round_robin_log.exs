defmodule Milk.Repo.Migrations.CreateRoundRobinLog do
  use Ecto.Migration

  def change do
    create table(:round_robin_log) do
      add :tournament_id, :integer
      add :match_list_str, :text
      add :rematch_index, :integer

      timestamps()
    end
  end
end
