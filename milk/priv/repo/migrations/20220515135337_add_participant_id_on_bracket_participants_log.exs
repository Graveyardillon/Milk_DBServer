defmodule Milk.Repo.Migrations.AddParticipantIdOnBracketParticipantsLog do
  use Ecto.Migration

  def change do
    alter table(:bracket_participants_log) do
      add :participant_id, :integer
    end
  end
end
