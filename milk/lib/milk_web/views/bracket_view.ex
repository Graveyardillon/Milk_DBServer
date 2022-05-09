defmodule MilkWeb.BracketView do
  use MilkWeb, :view

  alias Common.Tools

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
      enabled_bronze_medal_match: bracket.enabled_bronze_medal_match,
      id: bracket.id,
      owner_id: bracket.owner_id,
    }
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: Tools.create_error_message(error), data: nil}
  end
end
