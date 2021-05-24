defmodule Milk.Repo.Migrations.CreateMatchListWithFightResultLog do
  use Ecto.Migration

  def change do
    create table(:match_list_with_fight_result_log) do
      add :tournament_id, :integer
      add :match_list_with_fight_result_str, :text

      timestamps()
    end
  end
end
