defmodule Milk.Repo.Migrations.CreateAssistantLog do
  use Ecto.Migration

  def change do
    create table(:assistant_log) do
      add :tournament_id, :integer
      add :user_id, :integer

      timestamps()
    end

  end
end
