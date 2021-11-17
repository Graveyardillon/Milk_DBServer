defmodule Milk.Repo.Migrations.DropLives do
  use Ecto.Migration

  def change do
    table(:lives)
  end
end
