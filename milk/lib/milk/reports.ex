defmodule Milk.Reports do
  alias Milk.Accounts.UserReport
  alias Milk.Accounts.User
  alias Milk.Repo
  alias Milk.Accounts
  alias Common.Tools

  import Ecto.Query, warn: false

  def create(attrs \\ %{}) do
      reporter = Tools.to_integer_as_needed(attrs["reporter"])
      reportee = Tools.to_integer_as_needed(attrs["reportee"])

      %UserReport{reporter_id: reporter, reportee_id: reportee}
      |> UserReport.changeset(attrs)
      |> IO.inspect()
      |> Repo.insert()
  end

end