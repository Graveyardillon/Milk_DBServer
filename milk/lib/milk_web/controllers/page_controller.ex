defmodule MilkWeb.PageController do
  use MilkWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
