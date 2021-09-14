defmodule Milk.Repo.Migrations.AlterTournamentDiscordServerIdType do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      modify :discord_server_id, :string, null: true
    end
  end
end
