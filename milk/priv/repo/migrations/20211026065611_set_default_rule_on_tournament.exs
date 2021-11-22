defmodule Milk.Repo.Migrations.SetDefaultRuleOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      modify :rule, :string, default: "basic"
    end
  end
end
