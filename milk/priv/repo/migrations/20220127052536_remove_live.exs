defmodule Milk.Repo.Migrations.RemoveLive do
  use Ecto.Migration

  def change do
    drop table(:lives)
  end
end
