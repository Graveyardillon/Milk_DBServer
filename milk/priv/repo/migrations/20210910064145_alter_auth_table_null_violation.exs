defmodule Milk.Repo.Migrations.AlterAuthTableNullViolation do
  use Ecto.Migration

  def change do
    alter table(:auth) do
      modify :password, :string, null: true
    end
  end
end
