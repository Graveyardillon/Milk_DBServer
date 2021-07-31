defmodule Milk.Repo.Migrations.CreateMultipleSelection do
  use Ecto.Migration

  def change do
    create table(:multiple_selections) do
      add :tournament_id, references(:tournaments)
      add :state, :string, default: "not_selected"
      add :name, :string
    end
  end
end
