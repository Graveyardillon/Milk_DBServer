defmodule Milk.Repo.Migrations.CreateTeamRoundRobinWinCountTable do
  use Ecto.Migration

  def change do
    create table(:team_round_robin_win_count) do
      add :team_id, references(:teams, on_delete: :delete_all), null: true
      add :win_count, :integer()

      timestamps()
    end
  end
end
