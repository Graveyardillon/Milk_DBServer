defmodule Milk.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :title, :string
      add :icon_path, :string

      add :create_time, :timestamptz
      add :update_time, :timestamptz
    end

  end
end
