defmodule Milk.Reports.UserReport do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.User

  schema "user_reports" do
    belongs_to :reporter, User
    belongs_to :reportee, User
    field :report_type, :integer
    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:report_type])
    |> validate_required([:report_type])
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:reportee_id)
  end
end
