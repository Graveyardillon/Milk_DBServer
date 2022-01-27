defmodule Milk.Repo.Migrations.RenameTeamWinCountAndLog do
  use Ecto.Migration

  def change do
    drop table(:team_round_robin_win_count)

    create table(:team_win_count) do
      add :team_id, references(:teams, on_delete: :delete_all), null: true
      add :win_count, :integer

      timestamps()
    end

    drop table(:team_round_robin_win_count_log)

    create table(:team_win_count_log) do
      add :team_id, :integer
      add :win_count, :integer

      timestamps()
    end
  end
end
