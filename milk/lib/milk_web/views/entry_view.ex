defmodule MilkWeb.EntryView do
  use MilkWeb, :view

  def render("templates.json", %{templates: templates}) do
    %{
      result: true,
      templates: render_many(templates, __MODULE__, "template.json", as: :template)
    }
  end

  def render("template.json", %{template: template}) do
    %{
      title: template.title
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end
