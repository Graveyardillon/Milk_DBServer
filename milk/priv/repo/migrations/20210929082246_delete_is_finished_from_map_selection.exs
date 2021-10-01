defmodule Milk.Repo.Migrations.DeleteIsFinishedFromMapSelection do
  use Ecto.Migration

  def change do
    alter table(:map_selections) do
      remove :is_finished
    end
  end
end
