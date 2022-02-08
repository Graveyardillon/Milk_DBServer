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

  def render("entry_information_list.json", %{entry_information: entry_information}) do
    %{
      result: true,
      entry_information: render_many(entry_information, __MODULE__, "entry_information.json", as: :entry_information)
    }
  end

  def render("entry_information.json", %{entry_information: entry_information}) do
    %{
      title: entry_information.title,
      field: entry_information.field
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
