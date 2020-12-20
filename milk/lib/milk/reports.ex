defmodule Milk.Reports do
  alias Milk.Accounts.UserReport
  alias Milk.Accounts.User
  alias Milk.Repo
  alias Milk.Accounts
  alias Common.Tools
  alias Ecto.Multi


  import Ecto.Query, warn: false

  def create(attrs \\ %{}) do
    reporter = Tools.to_integer_as_needed(attrs["reporter"])
    reportee = Tools.to_integer_as_needed(attrs["reportee"])

    if Accounts.get_user(reporter) && Accounts.get_user(reportee) && reporter != reportee do
      Enum.map(attrs["report_type"], fn type ->
        %UserReport{reporter_id: reporter, reportee_id: reportee}
          |> UserReport.changeset(%{report_type: type})
          |> Repo.insert()
      end)
      {:ok}
    else
      {:error, "user error"}
    end
  end


end