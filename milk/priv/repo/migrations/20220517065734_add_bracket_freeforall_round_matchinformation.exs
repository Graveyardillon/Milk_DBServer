defmodule Milk.Repo.Migrations.AddBracketFreeforallRoundMatchinformation do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_round_matchinformation) do
      add :score, :integer
      add :round_id, references(:brackets_freeforall_round_information, on_delete: :delete_all)

      timestamps()
    end
  end
end
