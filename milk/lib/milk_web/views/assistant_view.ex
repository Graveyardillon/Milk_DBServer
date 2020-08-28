defmodule MilkWeb.AssistantView do
  use MilkWeb, :view
  alias MilkWeb.AssistantView

  def render("index.json", %{assistant: assistant}) do
    %{data: render_many(assistant, AssistantView, "assistant.json")}
  end

  def render("show.json", %{assistant: assistant}) do
    %{data: render_one(assistant, AssistantView, "assistant.json")}
  end

  def render("assistant.json", %{assistant: assistant}) do
    %{id: assistant.id}
  end
end
