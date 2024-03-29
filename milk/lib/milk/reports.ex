defmodule Milk.Reports do
  @moduledoc """
  通報関連のモジュール
  """
  import Ecto.Query, warn: false

  alias Common.Tools

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
      user_reports = insert_reports(report_types, reporter, reportee)

      {:ok, user_reports}
    else
      {:error, "user error"}
    end
  end

  defp insert_reports(report_types, reporter_id, reportee_id) do
    report_types
    |> Enum.map(fn type ->
      %UserReport{reporter_id: reporter_id, reportee_id: reportee_id}
      |> UserReport.changeset(%{report_type: type})
      |> Repo.insert()
      |> case do
        {:ok, report} -> report
        _             -> nil
      end
    end)
    |> Enum.reject(&is_nil(&1))
  end

  @doc """
  Create tournament report
  """
  def create_tournament_report(attrs = %{"report_types" => report_types}) when is_list(report_types) do
    attrs
    |> Map.put("report_type", report_types)
    |> Map.delete("report_types")
    |> __MODULE__.create_tournament_report()
  end

  def create_tournament_report(%{
        "reporter_id" => reporter_id,
        "report_type" => report_type,
        "tournament_id" => tournament_id
      })
      when is_list(report_type) do
    report_type
    |> Enum.map(fn type ->
      type = Tools.to_integer_as_needed(type)

      create_tournament_report(%{
        "reporter_id" => reporter_id,
        "report_type" => type,
        "tournament_id" => tournament_id
      })
    end)
    |> Enum.all?(fn tuple ->
      case tuple do
        {:ok, _} -> true
        _ -> false
      end
    end)
    |> if do
      {:ok, nil}
    else
      {:error, nil}
    end
  end

  def create_tournament_report(%{
        "reporter_id" => reporter_id,
        "report_type" => report_type,
        "tournament_id" => tournament_id
      }) do
    reporter_id = Tools.to_integer_as_needed(reporter_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Tournaments.load_tournament()
    |> case do
      nil ->
        {:error, nil}

      tournament ->
        insert_report_data(reporter_id, report_type, tournament)
    end
  end

  defp insert_report_data(reporter_id, report_type, tournament) do
    attrs =
      %{}
      |> Map.put("report_type", report_type)
      |> Map.put("capacity", tournament.capacity)
      |> Map.put("deadline", tournament.deadline)
      |> Map.put("description", tournament.description)
      |> Map.put("event_date", tournament.event_date)
      |> Map.put("name", tournament.name)
      |> Map.put("url", tournament.url)
      |> Map.put("thumbnail_path", tournament.thumbnail_path)
      |> Map.put("count", tournament.count)
      |> Map.put("game_name", tournament.game_name)
      |> Map.put("start_recruiting", tournament.start_recruiting)

    %TournamentReport{
      reporter_id: reporter_id,
      master_id: tournament.master_id,
      platform_id: tournament.platform_id
    }
    |> TournamentReport.changeset(attrs)
    |> Repo.insert()
  end
end
