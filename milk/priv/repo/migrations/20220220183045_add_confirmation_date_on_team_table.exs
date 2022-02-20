defmodule Milk.Repo.Migrations.AddConfirmationDateOnTeamTable do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :confirmation_date, :timestamptz
    end
  end
end
