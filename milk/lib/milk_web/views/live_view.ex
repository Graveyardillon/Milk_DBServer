defmodule MilkWeb.LiveView do
  use MilkWeb, :view
  alias MilkWeb.LiveView

  def render("list.json", %{lives: lives}) do
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
      streamer_id: live.streamer_id
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: create_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end