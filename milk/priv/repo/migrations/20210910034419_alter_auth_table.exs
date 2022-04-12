defmodule Milk.Repo.Migrations.AlterAuthTable do
  use Ecto.Migration

  def change do
    alter table(:auth) do
      add :is_oauth, :boolean, default: false
    end
  end
end
