defmodule Milk.Repo.Migrations.AddBracketParticipantTable do
  use Ecto.Migration

  def change do
    create table(:bracket_participants) do
      add :name, :string
      add :rank, :integer
      add :bracket_id, references(:brackets, on_delete: :delete_all)

      timestamps()
    end
  end
end
