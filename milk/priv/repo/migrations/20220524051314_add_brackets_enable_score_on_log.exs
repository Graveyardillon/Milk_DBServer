defmodule Milk.Repo.Migrations.AddBracketsEnableScoreOnLog do
  use Ecto.Migration

  def change do
    alter table(:brackets_log) do
      add :enabled_score, :boolean, default: false
    end
  end
end
