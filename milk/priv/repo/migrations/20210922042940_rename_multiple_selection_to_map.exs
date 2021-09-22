defmodule Milk.Repo.Migrations.RenameMultipleSelectionToMap do
  use Ecto.Migration

  def change do
    rename table(:tournaments), :enabled_multiple_selection, to: :enabled_map
    rename table(:tournament_custom_details), :multiple_selection_type, to: :map_rule


    alter table(:tournament_custom_details) do
      remove :multiple_selection_label
    end
  end
end
