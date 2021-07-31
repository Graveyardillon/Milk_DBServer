defmodule Milk.Repo.Migrations.CreateTournamentCustomDetailTable do
  use Ecto.Migration

  def change do
    create table(:tournament_custom_details) do
      add :tournament_id, references(:tournaments)
      add :coin_head_field, :string
      add :coin_tail_field, :string
      add :multiple_selection_type, :string

      timestamps()
    end
  end
end
