defmodule MilkWeb.EntryView do
  use MilkWeb, :view

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end
