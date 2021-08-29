defmodule Milk.Repo.Migrations.AddMultipleSelectionLabelOnCustomDetail do
  use Ecto.Migration

  def change do
    alter table(:tournament_custom_details) do
      add :multiple_selection_label, :string
    end
  end
end
