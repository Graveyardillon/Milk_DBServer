defmodule Milk.Repo.Migrations.CreateInvitationTable do
  use Ecto.Migration

  def change do
    create table(:team_invitations) do
      :destination_id, references(:users, on_delete: :delete_all)
      :sender_id, reference(:users, on_delete: :delete_all)
      :team_id, reference(:teams, on_delete: :delete_all)

      :text, :text

      timestamps()
    end
  end
end
