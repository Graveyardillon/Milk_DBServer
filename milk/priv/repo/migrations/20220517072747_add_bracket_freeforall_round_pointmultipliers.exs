defmodule Milk.Repo.Migrations.AddBracketFreeforallRoundPointmultipliers do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_round_pointmultipliers) do
      add :point, :integer

      belongs_to :match_information_id, references(:brackets_freeforall_round_matchinformation, on_delete: :delete_all)

      timestamps()
    end
  end
end
