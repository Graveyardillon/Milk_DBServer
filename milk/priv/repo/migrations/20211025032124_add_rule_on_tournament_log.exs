defmodule Milk.Repo.Migrations.AddRuleOnTournamentLog do
  use Ecto.Migration

  def change do
    alter table(:tournaments_log) do
      add :discord_server_id, :string
      add :enabled_coin_toss, :boolean
      add :enabled_map, :boolean
      add :rule, :string
      add :start_recruiting, :timestamptz
      add :url_token, :string
    end
  end
end
