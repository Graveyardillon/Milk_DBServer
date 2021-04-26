defmodule Milk.Reports do
  import Ecto.Query, warn: false

  alias Common.Tools
  alias Ecto.Multi
  alias Milk.{
    Accounts,
    Repo,
    Tournaments
  }
  alias Milk.Reports.{
    TournamentReport,
    UserReport
  }

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

  def create_tournament_report(%{"reporter_id" => reporter_id, "tournament_id" => tournament_id}) do
    reporter_id = Tools.to_integer_as_needed(reporter_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> case do
      {:ok, tournament} ->
        IO.inspect(tournament)
      {:error, _} ->
        IO.inspect("error")
    end
  end
end
