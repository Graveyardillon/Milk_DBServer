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

  def render("show.json", %{bracket: bracket}) do
    %{
      data: render_one(bracket, __MODULE__, "bracket.json"),
      result: true
    }
  end

  def render("bracket.json", %{bracket: bracket}) do
    %{
      name: bracket.name,
      url: bracket.url,
      rule: bracket.rule,
      enabled_bronze_medal_match: bracket.enabled_bronze_medal_match,
      id: bracket.id,
      owner_id: bracket.owner_id,
    }
  end

  def render("participant.json", %{participant: participant}) do
    %{
      name: participant.name,
      id: participant.id,
      bracket_id: participant.bracket_id
    }
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: Tools.create_error_message(error), data: nil}
  end
end
