defmodule MilkWeb.BracketController do
  @moduledoc """
  Bracket Controller
  """
  use MilkWeb, :controller

  alias Milk.Brackets
  alias Common.Tools

  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url, "enabled_bronze_medal_match" => enabled_bronze_medal_match}}) do
    with false          <- Brackets.is_url_duplicated?(url),
         {:ok, bracket} <- Brackets.create_bracket(%{name: name, owner_id: owner_id, url: url, rule: rule, enabled_bronze_medal_match: enabled_bronze_medal_match}) do
      render(conn, "show.json", bracket: bracket)
    else
      true            -> json(conn, %{result: false, error: "Urls is duplicated"})
      {:error, error} -> render(conn, "error.json", %{error: error.errors})
    end
  end
  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url}}) do
    __MODULE__.create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url, "enabled_bronze_medal_match" => false}})
  end

  # TODO: SQLインジェクションの確認
  def is_url_valid(conn, %{"url" => url}), do: json(conn, %{result: !Brackets.is_url_duplicated?(url)})

  def get_bracket(conn, %{"url" => url}) do
    bracket = Brackets.get_bracket_including_logs_by_url(url)

    if is_nil(bracket) do
      render(conn, "error.json", error: "bracket is nil")
    else
      render(conn, "show.json", bracket: bracket)
    end
  end

  def get_bracket(conn, %{"bracket_id" => bracket_id}) do
    bracket = Brackets.get_bracket(bracket_id)

    if is_nil(bracket) do
      render(conn, "error.json", error: "bracket is nil")
    else
      render(conn, "show.json", bracket: bracket)
    end
  end

  def get_brackets_by_owner_id(conn, %{"owner_id" => owner_id}) do
    brackets = owner_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_brackets_by_owner_id()

    render(conn, "index.json", brackets: brackets)
  end

  def get_bracket_logs_by_owner_id(conn, %{"owner_id" => owner_id}) do
    brackets = owner_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_bracket_logs_by_owner_id()

    render(conn, "index.json", brackets: brackets)
  end

  def create_participants(conn, %{"names" => names, "bracket_id" => bracket_id}) do
    with {:ok, _} <- Brackets.create_participants(names, bracket_id),
         {:ok, _} <- Brackets.initialize_brackets(bracket_id) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def get_participants(conn, %{"bracket_id" => bracket_id}) do
    participants = bracket_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_participants_including_log()

    render(conn, "index.json", participants: participants)
  end

  def delete_participant(conn, %{"bracket_id" => bracket_id, "participant_id" => participant_id}) do
    participant_id = Tools.to_integer_as_needed(participant_id)

    with participant when not is_nil(participant_id) <- Brackets.get_participant(participant_id),
         {:ok, _} <- Brackets.delete_participant(participant),
         {:ok, _} <- Brackets.initialize_brackets(bracket_id, [participant_id]) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def get_brackets_for_draw(conn, %{"bracket_id" => bracket_id}) do
    brackets = bracket_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_bracket_including_logs()
      |> Map.get(:match_list_with_fight_result_str)
      |> Code.eval_string()
      |> elem(0)
      |> generate_brackets()

    json(conn, %{result: true, data: brackets})
  end

  defp generate_brackets(nil), do: nil
  defp generate_brackets(brackets) do
    brackets
    |> Tournamex.brackets_with_fight_result()
    |> elem(1)
    |> List.flatten()
  end

  def edit_brackets(conn, %{"participant_id_list" => participant_id_list, "bracket_id" => bracket_id}) do
    participant_id_list
    |> Brackets.edit_brackets(bracket_id)
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def start(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Brackets.start()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def undo_start(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Brackets.undo_start()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def claim_lose(conn, %{"bracket_id" => bracket_id, "loser_participant_id" => loser_participant_id, "winner_participant_id" => winner_participant_id}) do
    with {:ok, _}                         <- Brackets.defeat_loser_participant(winner_participant_id, loser_participant_id, bracket_id),
         bracket when not is_nil(bracket) <- Brackets.get_bracket(bracket_id),
         {:ok, _}                         <- Brackets.disable_to_undo_start(bracket) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def delete(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Tools.to_integer_as_needed()
    |> Brackets.get_bracket()
    #|> Brackets.delete()
    |> Brackets.archive_and_delete()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def undo_progress(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Tools.to_integer_as_needed()
    |> Brackets.get_bracket()
    |> Brackets.undo_progress()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def finish(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Tools.to_integer_as_needed()
    |> Brackets.finish()
    |> case do
      {:ok, _}    -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def get_number(conn, _) do
    json(conn, %{num: Brackets.get_number()})
  end
end
