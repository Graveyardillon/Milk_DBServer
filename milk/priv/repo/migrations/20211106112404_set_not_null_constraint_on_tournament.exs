defmodule Milk.Repo.Migrations.SetNotNullConstraintOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      modify :rule, :string, default: "basic", null: false
    end
  end
end
