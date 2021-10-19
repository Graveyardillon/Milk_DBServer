defmodule Milk.Repo.Migrations.RefactorProfileTable do
  use Ecto.Migration

  def change do
    drop table(:profiles)

    alter table("entrants_log") do
      add :show_on_profile, :boolean, default: true
    end
  end
end
