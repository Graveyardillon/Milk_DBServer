defmodule Milk.Repo.Migrations.CreateInvitationTable do
  use Ecto.Migration

  def change do
    create table(:team_invitations) do
      add :destination_id, references(:users, on_delete: :delete_all)
      add :sender_id, references(:users, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all)

      add :text, :text

      timestamps()
    end
  end
end
