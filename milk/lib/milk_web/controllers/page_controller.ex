defmodule MilkWeb.PageController do
  use MilkWeb, :controller

  def index(conn, _params) do
    # Enum.map(1..2, fn x -> {:ok, jwd, _} = Guardian.encode_and_sign(x) 
    # jwd end)
    # |> Enum.uniq
    # |> length
    # json(conn, %{a: true})
    render(conn, "index.html")
  end
end
