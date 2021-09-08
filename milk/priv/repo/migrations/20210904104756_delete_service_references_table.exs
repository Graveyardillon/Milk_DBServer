defmodule Milk.Repo.Migrations.DeleteServiceReferencesTable do
  use Ecto.Migration

  def change do
    drop table(:service_references)
  end
end
