defmodule Milk.Repo.Migrations.AddBirthdayToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :birthday, :timestamptz, null: true
      add :birthday_private, :boolean, default: true
    end
  end
end
