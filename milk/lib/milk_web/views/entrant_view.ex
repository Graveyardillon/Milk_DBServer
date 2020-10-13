defmodule MilkWeb.EntrantView do
  use MilkWeb, :view
  alias MilkWeb.EntrantView

  def render("index.json", %{entrant: entrant}) do
    %{data: render_many(entrant, EntrantView, "entrant.json")}
  end

  def render("show.json", %{entrant: entrant}) do
    %{data: render_one(entrant, EntrantView, "entrant.json")}
  end

  def render("entrant.json", %{entrant: entrant}) do
    %{id: entrant.id,
      rank: entrant.rank}
  end

  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def render("multierror.json", %{error: error}) do
    %{result: false, error: create_message(error), data: nil}
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end
