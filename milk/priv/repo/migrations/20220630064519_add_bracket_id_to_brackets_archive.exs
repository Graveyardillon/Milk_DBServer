defmodule Milk.Repo.Migrations.AddBracketIdToBracketsArchive do
  use Ecto.Migration

  def change do
    alter table(:brackets_archive) do
      add :bracket_id, :integer
    end
  end
end
