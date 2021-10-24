defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  import Common.Sperm

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
        reports
        |> Enum.all?(&(!is_nil(&1)))
        |> if do
          :milk
          |> Application.get_env(:environment)
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
    report["reporter"]
    |> Tools.to_integer_as_needed()
    |> Accounts.get_user()
    ~> reporter

    report["reportee"]
    |> Tools.to_integer_as_needed()
    |> Accounts.get_user()
    ~> reportee

    DiscordWebhook.post_text_to_user_report_channel("#{reportee.name}が#{reporter.name}によって通報されました。")
  end

  @doc """
  Create a report for tournament.
  """
  def create_tournament_report(conn, %{"report" => report_params}) do
    report_params
    |> Reports.create_tournament_report()
    |> case do
      {:ok, _} ->
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
    report["reporter_id"]
    |> Tools.to_integer_as_needed()
    |> Accounts.get_user()
    ~> reporter

    report["tournament_id"]
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tournament()
    ~> tournament

    DiscordWebhook.post_text_to_tournament_report_channel("#{tournament.name}が#{reporter.name}によって通報されました。")
  end

  defp block_user_as_necessary(report) do
    reporter_id = Tools.to_integer_as_needed(report["reporter_id"])

    report["tournament_id"]
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tournament()
    |> Map.get(:master_id)
    ~> reportee_id

    report
    |> report_type_to_list()
    |> Enum.map(&Tools.to_integer_as_needed(&1))
    |> Enum.any?(&(&1 == 6))
    |> if do
      Relations.block(reporter_id, reportee_id)
    end
  end

  defp report_type_to_list(%{"report_types" => report_types}) when is_list(report_types), do: report_types
  defp report_type_to_list(%{"report_type" => report_type}) when is_list(report_type), do: report_type
  defp report_type_to_list(%{"report_type" => report_type}), do: [report_type]
end
