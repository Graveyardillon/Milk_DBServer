defmodule Milk.Repo.Migrations.AddBracketLogArchiveTable do
  use Ecto.Migration

  def change do
    create table(:brackets_archive) do
      add :name, :string
      add :owner_id, references(:users, on_delete: :nothing)
      add :url, :string
      add :enabled_bronze_medal_match, :boolean, default: false
      add :is_started, :boolean, default: false
      add :unable_to_undo_start, :boolean, default: false

      add :rule, :string
      add :match_list_str, :text
      add :match_list_with_fight_result_str, :text
      add :last_match_list_str, :text
      add :last_match_list_with_fight_result_str, :text

      timestamps()
    end
  end
end
