defmodule Milk.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :user_id, :integer
      add :content_id, :integer
      add :content_type, :string

      add :create_time, :timestamptz
      add :update_time, :timestamptz
    end
  end
end
