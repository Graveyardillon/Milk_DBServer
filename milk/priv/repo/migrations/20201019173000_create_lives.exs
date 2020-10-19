defmodule Milk.Repo.Migrations.CreateLives do
  use Ecto.Migration

  def change do
    create table(:lives) do
      add :name, :string
      add :number_of_viewers, :integer, default: 0
      add :tournament_id, references(:tournament, on_delete: :delete_all)
      add :streamer_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

  end
end
