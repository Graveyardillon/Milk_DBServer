defmodule Milk.Repo.Migrations.AddBracketsFreeforallPointmultipliercategories do
  use Ecto.Migration

  def change do
    create table(:brackets_freeforall_pointmultipliercategories) do
      add :name, :string
      add :multiplier, :float
      add :bracket_id, references(:brackets, on_delete: :delete_all)

      timestamps()
    end
  end
end
