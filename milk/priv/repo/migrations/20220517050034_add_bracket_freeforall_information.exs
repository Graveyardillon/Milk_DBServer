defmodule Milk.Repo.Migrations.AddBracketFreeforallInformation do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_information) do
      add :round_number, :integer
      add :match_number, :integer
      add :round_capacity, :integer
      add :enable_point_multiplier, :boolean, default: false
      add :bracket_id, references(:brackets, on_delete: :delete_all)

      timestamps()
    end
  end
end
