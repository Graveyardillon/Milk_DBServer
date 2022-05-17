defmodule Milk.Repo.Migrations.AddBracketFreeforallStatus do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_status) do
      add :current_round_index, :integer, default: 0

      add :bracket_id, references(:brackets, on_delete: :delete_all)

      timestamps()
    end
  end
end
