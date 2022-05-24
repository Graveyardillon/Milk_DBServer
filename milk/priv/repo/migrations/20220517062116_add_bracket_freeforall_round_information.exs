defmodule Milk.Repo.Migrations.AddBracketFreeforallRoundInformation do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_round_information) do
      add :table_id, references(:brackets_freeforall_round_table, on_delete: :delete_all)
      add :participant_id, references(:bracket_participants, on_delete: :delete_all)

      timestamps()
    end
  end
end
