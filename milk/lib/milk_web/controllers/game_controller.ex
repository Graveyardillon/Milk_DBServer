defmodule MilkWeb.GameController do
  use MilkWeb, :controller

  alias Milk.Games
  alias Milk.Games.Game

  action_fallback MilkWeb.FallbackController

  def list(conn, _params) do #TODO: リストに何もなかった場合の返答
    games = Games.list_games()
    render(conn, "list.json", games: games)
  end

  def add(conn, %{"game" => game_params}) do 
    with {:ok, %Game{} = game} <- Games.add_game(game_params) do
      conn
        |> render("show.json", game: game)
    end
  end

  # def show(conn, %{"id" => id}) do
  #   game = Games.get_game!(id)
  #   render(conn, "show.json", game: game)
  # end

  # def update(conn, %{"id" => id, "game" => game_params}) do
  #   game = Games.get_game!(id)

  #   with {:ok, %Game{} = game} <- Games.update_game(game, game_params) do
  #     render(conn, "show.json", game: game)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   game = Games.get_game!(id)

  #   with {:ok, %Game{}} <- Games.delete_game(game) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
