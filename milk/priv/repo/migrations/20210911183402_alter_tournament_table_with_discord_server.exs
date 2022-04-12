defmodule Milk.Repo.Migrations.AlterTournamentTableWithDiscordServer do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :discord_server_id, :integer
    end
  end
end
