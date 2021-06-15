defmodule Milk.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :token, :string

      timestamps()
    end

    create unique_index(:devices, [:token])
  end
end
