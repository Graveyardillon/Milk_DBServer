defmodule Milk.Repo.Migrations.RemoveActionHistory do
  use Ecto.Migration

  def change do
    drop table(:action_histories)
  end
end
