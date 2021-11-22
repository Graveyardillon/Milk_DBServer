defmodule Milk.Repo.Migrations.AddRuleLabelOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :rule, :string
    end
  end
end
