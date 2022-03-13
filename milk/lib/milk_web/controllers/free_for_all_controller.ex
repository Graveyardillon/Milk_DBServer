defmodule MilkWeb.FreeForAllController do
  @moduledoc """
  複雑な処理になりそうだったので、tournament_controllerでなくこっちに記述
  """
  use MilkWeb, :controller
  import Common.Sperm

  alias Common.Tools

  alias Milk.Tournaments.Rules.FreeForAll
  alias Milk.Tournaments
  alias Milk.Log

  def get_information(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_freeforall_information_by_tournament_id()
    ~> information

    render(conn, "information.json", information: information)
  end

  def get_categories(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_categories()
    ~> categories

    render(conn, "categories.json", categories: categories)
  end

  def get_tables(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_tables_by_tournament_id()
    |> get_tables_log_as_needed(tournament_id)
    ~> tables

    render(conn, "tables.json", tables: tables)
  end

  defp get_tables_log_as_needed(nil, tournament_id), do: get_tables_log_as_needed([], tournament_id)
  defp get_tables_log_as_needed([], tournament_id) do
    tournament_id
    |> Log.get_tournament_log_by_tournament_id()
    |> Map.get(:id)
    |> FreeForAll.get_table_logs_by_tournament_log_id()
  end
  defp get_tables_log_as_needed(tables, _), do: tables

  def get_round_information(conn, %{"table_id" => table_id}) do
    table_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_round_information()
    |> get_round_information_log_as_needed(table_id)
    ~> information_list

    render(conn, "round_information.json", %{information: information_list})
  end

  defp get_round_information_log_as_needed(nil, table_log_id), do: get_round_information_log_as_needed([], table_log_id)
  defp get_round_information_log_as_needed([], table_log_id) do
    FreeForAll.get_round_information_logs_by_table_log_id(table_log_id)
  end
  defp get_round_information_log_as_needed(round_info, _), do: round_info

  def get_round_team_information(conn, %{"table_id" => table_id}) do
    table_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_round_team_information()
    |> get_round_team_information_log_as_needed(table_id)
    ~> information_list

    render(conn, "round_team_information.json", team_information: information_list)
  end

  defp get_round_team_information_log_as_needed(nil, table_log_id), do: get_round_team_information_log_as_needed([], table_log_id)
  defp get_round_team_information_log_as_needed([], table_log_id) do
    FreeForAll.get_team_round_information_logs_by_table_log_id(table_log_id)
  end
  defp get_round_team_information_log_as_needed(information, _), do: information

  def get_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_match_information()
    |> get_match_information_log_as_needed(round_information_id)
    ~> match_information_list

    render(conn, "match_information.json", match_information: match_information_list)
  end

  defp get_match_information_log_as_needed(nil, round_information_log_id), do: get_match_information_log_as_needed([], round_information_log_id)
  defp get_match_information_log_as_needed([], round_information_log_id) do
    FreeForAll.get_match_information_logs_by_round_information_log_id(round_information_log_id)
  end
  defp get_match_information_log_as_needed(match_information_list, _), do: match_information_list

  def load_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.load_match_information()
    |> load_match_information_log_as_needed(round_information_id)
    ~> match_information_list

    render(conn, "load_match_information.json", match_information: match_information_list)
  end

  defp load_match_information_log_as_needed(nil, round_information_log_id), do: load_match_information_log_as_needed([], round_information_log_id)
  defp load_match_information_log_as_needed([], round_information_log_id) do
    FreeForAll.load_match_information_logs_by_round_information_log_id(round_information_log_id)
  end

  def get_team_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_team_match_information()
    |> get_team_match_information_log_as_needed(round_information_id)
    ~> match_information_list

    render(conn, "match_information.json", match_information: match_information_list)
  end

  defp get_team_match_information_log_as_needed(nil, round_information_id), do: get_team_match_information_log_as_needed([], round_information_id)
  defp get_team_match_information_log_as_needed([], round_information_id) do
    FreeForAll.get_team_match_information_logs_by_round_information_log_id(round_information_id)
  end

  def load_team_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.load_team_match_information()
    |> load_team_match_information_log_as_needed(round_information_id)
    ~> match_information_list

    render(conn, "load_match_information.json", match_information: match_information_list)
  end

  defp load_team_match_information_log_as_needed(nil, round_information_log_id), do: load_team_match_information_log_as_needed([], round_information_log_id)
  defp load_team_match_information_log_as_needed([], round_information_log_id) do
    FreeForAll.load_team_match_information_logs_by_round_information_log_id(round_information_log_id)
  end
  defp load_team_match_information_log_as_needed(info, _), do: info

  def get_member_match_information(conn, %{"team_match_information_id" => team_match_information_id}) do
    team_match_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_member_match_information_list()
    |> get_member_match_information_log_as_needed(team_match_information_id)
    ~> match_information_list

    render(conn, "member_match_information.json", match_information: match_information_list)
  end

  defp get_member_match_information_log_as_needed(nil, info_id), do: get_member_match_information_log_as_needed([], info_id)
  defp get_member_match_information_log_as_needed([], info_id) do
    FreeForAll.get_member_match_information_logs_as_needed(info_id)
  end
  defp get_member_match_information_log_as_needed(info, _), do: info

  def load_member_match_information(conn, %{"team_match_information_id" => team_match_information_id}) do
    team_match_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.load_member_match_information_list()
    |> load_member_match_information_log_as_needed(team_match_information_id)
    ~> match_information_list

    render(conn, "load_member_match_information.json", match_information: match_information_list)
  end

  defp load_member_match_information_log_as_needed(nil, info_id), do: load_team_match_information_log_as_needed([], info_id)
  defp load_member_match_information_log_as_needed([], info_id) do
    FreeForAll.load_member_match_information_logs_as_needed(info_id)
  end
  defp load_member_match_information_log_as_needed(info, _), do: info

  def get_current_status(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_status_by_tournament_id()
    ~> status

    render(conn, "status.json", status: status)
  end

  def claim_scores(conn, %{"tournament_id" => tournament_id, "table_id" => table_id, "scores" => scores}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    table_id = Tools.to_integer_as_needed(table_id)
    tournament = Tournaments.get_tournament(tournament_id)

    with {:ok, _} <- FreeForAll.claim_scores(tournament, table_id, scores),
         {:ok, _} <- FreeForAll.increase_current_match_index(table_id),
         {:ok, _} <- FreeForAll.finish_table_as_needed(table_id),
         {:ok, _} <- FreeForAll.proceed_to_next_round_as_needed(tournament) do
      json(conn, %{result: true})
    else
      {:error, error} -> json(conn, %{result: false, error: error})
      _               -> json(conn, %{result: true})
    end
  end

  def claim_scores(conn, %{"tournament_id" => tournament_id, "table_id" => table_id, "scores_with_categories" => scores_with_categories}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    table_id = Tools.to_integer_as_needed(table_id)
    tournament = Tournaments.get_tournament(tournament_id)

    # NOTE: カテゴリidと一緒にスコアを送信 [%{"scores" => [%{"category_id" => 1, "score" => 1}], "match_information_id" => 1}]
    with {:ok, _} <- FreeForAll.claim_scores_with_categories(tournament, table_id, scores_with_categories),
         {:ok, _} <- FreeForAll.increase_current_match_index(table_id),
         {:ok, _} <- FreeForAll.finish_table_as_needed(table_id),
         {:ok, _} <- FreeForAll.proceed_to_next_round_as_needed(tournament) do
        if is_nil(Tournaments.get_tournament(tournament_id)) do
          render(conn, "finished.json", %{messages: Tournaments.all_states!(tournament_id), name: tournament.name})
        else
          json(conn, %{result: true})
        end
    else
      {:error, error} -> json(conn, %{result: false, error: error})
      _               -> json(conn, %{result: true})
    end
  end

  def update_information(conn, %{"tournament_id" => tournament_id, "information" => information}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_freeforall_information_by_tournament_id()
    |> FreeForAll.update_freeforall_information(information)
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def update_categories(conn, %{"categories" => categories}) do
    categories
    |> FreeForAll.update_categories()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end
end
