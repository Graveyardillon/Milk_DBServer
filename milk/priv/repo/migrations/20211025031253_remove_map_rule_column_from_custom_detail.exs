defmodule Milk.Repo.Migrations.RemoveMapRuleColumnFromCustomDetail do
  use Ecto.Migration

  def change do
    alter table(:tournament_custom_details) do
      remove :map_rule
    end
  end
end
