defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  require Logger

  alias Common.Tools

  alias Milk.{
    Accounts,
    DiscordWebhook,
    Relations,
    Reports,
    Tournaments
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
          Application.get_env(:milk, :environment)
          |> Kernel.==(:test)
          |> unless do
            notify_user_report(report_params)
          end

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

    (reportee.name <> "が" <> reporter.name <> "によって通報されました。")
    |> DiscordWebhook.post_text_to_user_report_channel()
  end

  @doc """
  Create a report for tournament.
  """
  def create_tournament_report(conn, %{"report" => report_params}) do
    report_params
    |> Reports.create_tournament_report()
    |> case do
      {:ok, report} ->
        Application.get_env(:milk, :environment)
        |> Kernel.==(:test)
        |> unless do
          notify_tournament_report(report_params)
        end

        block_user_as_necessary(report_params)
        json(conn, %{result: true})

      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end

  defp notify_tournament_report(report) do
    reporter =
      report["reporter_id"]
      |> Tools.to_integer_as_needed()
      |> Accounts.get_user()

    tournament =
      report["tournament_id"]
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_tournament()

    (tournament.name <> "が" <> reporter.name <> "によって通報されました。")
    |> DiscordWebhook.post_text_to_tournament_report_channel()
  end

  defp block_user_as_necessary(report) do
    reporter_id =
      report["reporter_id"]
      |> Tools.to_integer_as_needed()

    reportee_id =
      report["tournament_id"]
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_tournament()
      |> Map.get(:master_id)

    report["report_type"]
    |> is_integer()
    |> if do
      [report["report_type"]]
    else
      report["report_type"]
    end
    |> Enum.map(fn type ->
      Tools.to_integer_as_needed(type)
    end)
    |> Enum.any?(fn type ->
      type == 6
    end)
    |> if do
      Relations.block(reporter_id, reportee_id)
    end
    |> case do
      {:ok, _} ->
        Logger.info(to_string(reporter_id) <> " Blocked " <> to_string(reportee_id))

      _ ->
        Logger.info(
          to_string(reporter_id) <> " Did not block " <> to_string(reportee_id) <> "but reported"
        )
    end
  end
end
