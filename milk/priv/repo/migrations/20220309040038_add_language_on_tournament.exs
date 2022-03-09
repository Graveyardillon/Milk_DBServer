defmodule Milk.Repo.Migrations.AddLanguageOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :language, :string, null: true
    end
  end
end
