defmodule Milk.Repo.Migrations.AddBracketParticipantLogTable do
  use Ecto.Migration

  def change do
    create table(:bracket_participants_log) do
      add :name, :string
      add :bracket_id, references(:brackets_log, on_delete: :delete_all)

      timestamps()
    end
  end
end
