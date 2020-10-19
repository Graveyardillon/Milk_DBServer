defmodule MilkWeb.LiveController do
  use MilkWeb, :controller

  alias Milk.Lives.Live
  alias Milk.Lives

  def create(conn, %{"live" => live_params}) do
    case Lives.create_live(live_params) do
      {:ok, %Live{} = live} ->
        IO.inspect live
        conn
        |> render("show.json", live: live)
      
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end
end