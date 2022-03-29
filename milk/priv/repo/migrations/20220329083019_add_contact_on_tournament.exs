defmodule Milk.Repo.Migrations.AddContactOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :contact, :string
    end
  end
end
