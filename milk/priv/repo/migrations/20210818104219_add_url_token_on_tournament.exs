defmodule Milk.Repo.Migrations.AddUrlTokenOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :url_token, :string
    end
  end
end
