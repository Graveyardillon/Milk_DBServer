defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Milk.{
    Accounts,
    DiscordWebhook,
    Reports
  }

  @doc """
  Create a report for user.
  """
  def create_user_report(conn, %{"report" => report_params}) do
    case Reports.create_user_report(report_params) do
      {:ok, reports} ->
        Enum.all?(reports, fn report ->
          !is_nil(reports)
        end)
        |> if do
          notify_user_report(report_params)
          json(conn, %{result: true})
        else
          json(conn, %{result: false, error: "Could not create report"})
        end
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end

  defp notify_user_report(report) do
    reporter =
      report["reporter"]
      |> Tools.to_integer_as_needed()
      |> Accounts.get_user()

    reportee =
      report["reportee"]
      |> Tools.to_integer_as_needed()
      |> Accounts.get_user()

    reportee.name <> "が" <> reporter.name <> "によって通報されました。"
    |> DiscordWebhook.post_text()
  end

  @doc """
  Create a report for tournament.
  """
  def create_tournament_report(conn, %{"report" => report_params}) do
    report_params
    |> Reports.create_tournament_report()
    |> case do
      {:ok, report} ->
        json(conn, %{result: true})
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end
end
