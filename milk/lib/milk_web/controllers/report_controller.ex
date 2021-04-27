defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  alias Milk.Reports

  def create_user_report(conn, %{"report" => report_params}) do
    case Reports.create_user_report(report_params) do
      {:ok, reports} ->
        Enum.all?(reports, fn report ->
          !is_nil(reports)
        end)
        |> if do
          json(conn, %{result: true})
        else
          json(conn, %{result: false, error: "Could not create report"})
        end
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end

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
