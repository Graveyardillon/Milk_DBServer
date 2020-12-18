defmodule MilkWeb.ReportController do
  use MilkWeb, :controller

  alias Milk.Reports 

  def create(conn, %{"report" => report_params}) do
    case Reports.create(report_params) do
      {:ok, _relation} ->
        json(conn, %{result: true})
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end
end