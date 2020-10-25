defmodule Milk.Repo.Migrations.CreatePlatform do
  use Ecto.Migration

  def change do
    create table(:platforms) do
      add :name, :string
    end
  end
end
