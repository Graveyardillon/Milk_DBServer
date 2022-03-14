defmodule Milk.Repo.Migrations.TournamentsRulesFreeforalllogInformation do
  use Ecto.Migration

  def change do
    create table(:tournaments_rules_freeforalllog_information) do
      add :round_number, :integer
      add :match_number, :integer
      add :round_capacity, :integer
      add :enable_point_multiplier, :boolean, default: false
      add :is_truncation_enabled, :boolean, default: false
      add :tournament_id, references(:tournaments_log, on_delete: :delete_all)

      timestamps()
    end
  end
end
