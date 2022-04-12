defmodule MilkWeb.DiscordView do
  use MilkWeb, :view

  alias Common.Tools

  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: Tools.create_error_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end
