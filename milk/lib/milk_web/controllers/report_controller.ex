defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  alias Milk.Reports

  def create(conn, %{"report" => report_params}) do
    case Reports.create(report_params) do
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
end
