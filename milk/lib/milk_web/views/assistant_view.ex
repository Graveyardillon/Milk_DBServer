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

  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: create_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end
