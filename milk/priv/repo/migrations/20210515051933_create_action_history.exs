defmodule Milk.Repo.Migrations.CreateActionHistory do
  use Ecto.Migration

  def change do
    create table(:action_histories) do
      add :user_id, :integer
      add :game_name, :string

      timestamps()
    end
  end
end
