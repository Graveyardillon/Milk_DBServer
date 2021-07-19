defmodule Milk.Repo.Migrations.CaseInsansitiveUsername do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :name, :citext, null: false
    end
  end
end
