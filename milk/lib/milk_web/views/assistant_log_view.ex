defmodule MilkWeb.AssistantLogView do
  use MilkWeb, :view
  alias MilkWeb.AssistantLogView

  def render("index.json", %{assistant_log: assistant_log}) do
    %{data: render_many(assistant_log, AssistantLogView, "assistant_log.json")}
  end

  def render("show.json", %{assistant_log: assistant_log}) do
    %{data: render_one(assistant_log, AssistantLogView, "assistant_log.json")}
  end

  def render("assistant_log.json", %{assistant_log: assistant_log}) do
    %{id: assistant_log.id,
      tournament_id: assistant_log.tournament_id,
      user_id: assistant_log.user_id}
  end
end
