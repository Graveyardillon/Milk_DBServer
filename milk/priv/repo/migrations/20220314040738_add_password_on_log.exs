defmodule Milk.Repo.Migrations.AddPasswordOnLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :password, :string
    end
  end
end
