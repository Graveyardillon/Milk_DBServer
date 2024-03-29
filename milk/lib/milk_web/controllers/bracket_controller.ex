defmodule MilkWeb.BracketController do
  @moduledoc """
  Bracket Controller
  """
  use MilkWeb, :controller

  alias Milk.Brackets
  alias Milk.Brackets.{
    Bracket,
    FreeForAll
  }
  alias Common.Tools

  def create_bracket(conn, %{"brackets" => attrs}) do
    with {:ok, _}       <- validate_on_create_bracket(attrs),
         false          <- Brackets.is_url_duplicated?(attrs["url"]),
         {:ok, bracket} <- Brackets.create_bracket(attrs),
         {:ok, _}       <- create_other_information_on_create_bracket(bracket, attrs) do
      render(conn, "show.json", bracket: bracket)
    else
      true                                      -> json(conn, %{result: false, error: "Urls is duplicated"})
      {:error, %Ecto.Changeset{errors: errors}} -> render(conn, "error.json", %{error: errors})
      {:error, error} when is_binary(error)     -> render(conn, "error.json", error: error)
    end
  end

  defp validate_on_create_bracket(%{"rule" => nil}),                                                                           do: {:error, "rule is nil on create bracket"}
  defp validate_on_create_bracket(%{"rule" => "basic"}),                                                                       do: {:ok, nil}
  defp validate_on_create_bracket(%{"rule" => "freeforall", "round_capacity" => _, "match_number" => _, "round_number" => _}), do: {:ok, nil}
  defp validate_on_create_bracket(_),                                                                                          do: {:error, "invalid parameters on create bracket"}

  defp create_other_information_on_create_bracket(_, %{"rule" => "basic"}), do: {:ok, nil}
  defp create_other_information_on_create_bracket(%Bracket{id: bracket_id}, %{"rule" => "freeforall"} = attrs) do
    attrs
    |> Map.put("bracket_id", bracket_id)
    |> FreeForAll.create_freeforall_information()
  end
  defp create_other_information_on_create_bracket(_, _), do: {:ok, nil}

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
         {:ok, _} <- initialize_brackets_or_tables(bracket_id) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  defp initialize_brackets_or_tables(bracket_id) do
    bracket = Brackets.get_bracket(bracket_id)

    if bracket.rule == "basic" || is_nil(bracket.rule) do
      Brackets.initialize_brackets(bracket_id)
    else
      FreeForAll.initialize_round_tables(bracket, 0)
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

  def claim_scores(conn, %{"bracket_id" => bracket_id, "winner_participant_id" => winner_participant_id, "winner_score" => winner_score, "loser_participant_id" => loser_participant_id, "loser_score" => loser_score}) do
    with %Bracket{enabled_score: true} = bracket <- Brackets.get_bracket(bracket_id),
         {:ok, _}                                <- Brackets.defeat_loser_participant_by_scores(winner_participant_id, winner_score, loser_participant_id, loser_score, bracket),
         bracket when not is_nil(bracket)        <- Brackets.get_bracket(bracket_id),
         {:ok, _}                                <- Brackets.disable_to_undo_start(bracket) do
      json(conn, %{result: true})
    else
      nil -> json(conn, %{result: false, error: "Bracket is nil"})
      _   -> json(conn, %{result: false})
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

  def claim_bronze_lose(conn,  %{"bracket_id" => bracket_id, "winner_participant_id" => winner_participant_id}) do
    bracket_id = Tools.to_integer_as_needed(bracket_id)

    with bracket when not is_nil(bracket) <- Brackets.get_bracket(bracket_id),
         {:ok, _}                         <- Brackets.claim_bronze_match_winner(bracket, winner_participant_id) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def claim_bronze_scores(conn, %{"bracket_id" => bracket_id, "winner_participant_id" => winner_participant_id, "winner_score" => winner_score, "loser_score" => loser_score}) do
    bracket_id = Tools.to_integer_as_needed(bracket_id)

    with bracket when not is_nil(bracket) <- Brackets.get_bracket(bracket_id),
         {:ok, _}                         <- Brackets.claim_bronze_scores(bracket, winner_participant_id, winner_score, loser_score) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def delete(conn, %{"bracket_id" => bracket_id}) do
    bracket_id
    |> Tools.to_integer_as_needed()
    |> Brackets.get_bracket()
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

  def is_bronze_match?(conn, %{"bracket_id" => bracket_id}) do
    is_bronze_match = bracket_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_bracket_including_logs()
      |> Brackets.is_bronze_match?()

    json(conn, %{result: is_bronze_match})
  end

  def get_bronze_match_winner(conn, %{"bracket_id" => bracket_id}) do
    participant = bracket_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_bracket_including_logs()
      |> do_get_bronze_match_winner()

    render(conn, "show.json", participant: participant)
  end

  defp do_get_bronze_match_winner(nil),     do: nil
  defp do_get_bronze_match_winner(bracket) do
    if is_nil(bracket.bronze_match_winner_participant_id) do
      nil
    else
      Brackets.get_participant_including_logs(bracket.bronze_match_winner_participant_id)
    end
  end

  # NOTE: Free For All用
  def get_tables(conn, %{"bracket_id" => bracket_id}) do
    tables = bracket_id
      |> Tools.to_integer_as_needed()
      |> FreeForAll.get_tables()

    render(conn, "index.json", tables: tables)
  end
end
