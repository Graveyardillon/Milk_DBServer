defmodule Milk.Repo.Migrations.CreateTeamRoundRobinWinCountTableLog do
  use Ecto.Migration

  def change do
    create table(:team_round_robin_win_count_log) do
      add :team_id, :integer
      add :win_count, :integer

      timestamps()
    end
  end
end
