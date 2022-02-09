defmodule Milk.Repo.Migrations.CreateEntryInformationTable2 do
  use Ecto.Migration

  def change do
    create table(:entry_information) do
      add :entry_id, references(:entries, on_delete: :delete_all)
      add :title, :string
      add :field, :text

      timestamps()
    end
  end
end
