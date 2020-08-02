defmodule Milk.Repo.Migrations.AddBioToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bio, :string, null: true
    end
  end
end
