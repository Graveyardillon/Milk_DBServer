defmodule MilkWeb.LiveView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.LiveView

  def render("index.json", %{lives: lives}) do
    %{data: render_many(lives, LiveView, "live.json")}
  end

  def render("show.json", %{live: live}) do
    %{data: render_one(live, LiveView, "live.json")}
  end

  def render("live.json", %{live: live}) do
    %{
      id: live.id,
      name: live.name,
      number_of_viewers: live.number_of_viewers,
      streamer_id: live.streamer_id,
      tournament_id: live.tournament_id
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: Tools.create_error_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end
