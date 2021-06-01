defmodule MilkWeb.AssistantView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.AssistantView

  def render("index.json", %{assistant: assistant}) do
    %{data: render_many(assistant, AssistantView, "assistant.json")}
  end

  def render("show.json", %{assistant: assistant}) do
    %{data: render_one(assistant, AssistantView, "assistant.json")}
  end

  def render("assistant.json", %{assistant: assistant}) do
    %{
      id: assistant.id,
      user_id: assistant.user_id,
      tournament_id: assistant.tournament_id,
      create_time: assistant.create_time,
      update_time: assistant.update_time
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: Tools.create_error_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def render("error_string.json", %{data: data}) do
    if data.data do
      %{
        result: true,
        error: data.error,
        data: render_many(data.data, AssistantView, "assistant.json")
      }
    else
      %{result: false, error: data.error, data: nil}
    end
  end
end
