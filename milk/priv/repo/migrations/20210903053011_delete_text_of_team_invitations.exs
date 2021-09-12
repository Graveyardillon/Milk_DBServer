defmodule Milk.Repo.Migrations.DeleteTextOfTeamInvitations do
  use Ecto.Migration

  def change do
    alter table("team_invitations") do
      remove :text
    end
  end
end
