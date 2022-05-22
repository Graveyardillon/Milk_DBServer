defmodule MilkWeb.BracketView do
  use MilkWeb, :view

  alias Common.Tools

  def render("index.json", %{brackets: brackets}) do
    %{
      data: render_many(brackets, __MODULE__, "bracket.json"),
      result: true
    }
  end

  def render("index.json", %{participants: participants}) do
    %{
      data: render_many(participants, __MODULE__, "participant.json", as: :participant),
      result: true
    }
  end

  def render("index.json", %{tables: tables}) do
    %{
      data: render_many(tables, __MODULE__, "table.json", as: :table),
      result: true
    }
  end

  def render("show.json", %{bracket: bracket}) do
    %{
      data: render_one(bracket, __MODULE__, "bracket.json"),
      result: true
    }
  end

  def render("show.json", %{participant: participant}) do
    %{
      data: render_one(participant, __MODULE__, "participant.json", as: :participant),
      result: true
    }
  end

  def render("bracket.json", %{bracket: bracket}) do
    %{
      name: bracket.name,
      url: bracket.url,
      rule: bracket.rule,
      is_started: bracket.is_started,
      enabled_bronze_medal_match: bracket.enabled_bronze_medal_match,
      enabled_score: bracket.enabled_score,
      unable_to_undo_start: bracket.unable_to_undo_start,
      last_match_list_str: bracket.last_match_list_str,
      id: bracket.id,
      owner_id: bracket.owner_id,
      is_finished: if Map.has_key?(bracket, :is_finished) do
          bracket.is_finished
        else
          false
        end
    }
  end

  def render("participant.json", %{participant: participant}) do
    %{
      name: participant.name,
      id: participant.id,
      bracket_id: participant.bracket_id
    }
  end

  def render("table.json", %{table: table}) do
    %{
      id: table.id,
      name: table.name,
      round_index: table.round_index,
      bracket_id: table.bracket_id,
      is_finished: table.is_finished,
      current_match_index: table.current_match_index
    }
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: Tools.create_error_message(error), data: nil}
  end
end
