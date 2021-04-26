defmodule Milk.Reports do
  alias Common.Tools
  alias Milk.{
    Accounts,
    Repo
  }
  alias Milk.Reports.UserReport
  alias Ecto.Multi

  import Ecto.Query, warn: false

  def create_user_report(%{"reporter" => reporter, "reportee" => reportee, "report_types" => report_types}) do
    reporter = Tools.to_integer_as_needed(reporter)
    reportee = Tools.to_integer_as_needed(reportee)

    if Accounts.get_user(reporter) && Accounts.get_user(reportee) && reporter != reportee do
      user_reports =
        Enum.map(report_types, fn type ->
          with {:ok, report} <-
            %UserReport{reporter_id: reporter, reportee_id: reportee}
            |> UserReport.changeset(%{report_type: type})
            |> Repo.insert() do
            report
          else
            _ -> nil
          end
        end)
      {:ok, user_reports}
    else
      {:error, "user error"}
    end
  end
end
