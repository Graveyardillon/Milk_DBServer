defmodule Milk.Repo.Migrations.CreateUserReports do
  use Ecto.Migration

  def change do
    create table(:user_reports) do
      add :report_type, :integer
      add :reporter_id, references(:users, on_delete: :delete_all), null: false
      add :reportee_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
