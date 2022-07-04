defmodule Milk.Repo.Migrations.AddBracketsEnableScore do
  use Ecto.Migration

  def change do
    alter table(:brackets) do
      add :enabled_score, :boolean, default: false
    end
  end
end
