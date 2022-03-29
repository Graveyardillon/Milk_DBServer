defmodule Milk.Repo.Migrations.AddLanguageOnTournamentLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :language, :string
    end
  end
end
