defmodule Milk.Repo.Migrations.AddBracketFreeforallRoundTable do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_round_table) do
      add :name, :string
      add :round_index, :integer
      add :is_finished, :boolean
      add :current_match_index, :integer

      add :bracket_id, references(:brackets, on_delete: :delete_all)

      timestamps()
    end
  end
end
