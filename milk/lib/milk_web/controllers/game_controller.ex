defmodule MilkWeb.GameController do
  use MilkWeb, :controller

  alias Milk.Games
  alias Milk.Games.Game
  alias Ecto.Multi
  alias Milk.Repo

  action_fallback MilkWeb.FallbackController

  def list(conn, _params) do #TODO: リストに何もなかった場合の返答
    games = Games.list_games()
    render(conn, "list.json", games: games)
  end

  def create(conn, %{"game" => game_params}) do 
    with {:ok, %Game{} = game} <- Games.create_game(game_params) do
      conn
      |> render("show.json", game: game)
    end
  end

  # TODO: multiにしたけどいい実装方法なのか微妙だからまた見てもらう
  # てかControllerでRepo操作するのだめやん
  def create(attrs \\ %{}) do
    case Multi.new
    |> Multi.insert(:game, Game.changeset(%Game{}, attrs))
    |> Repo.transaction() do
      {:ok, game} -> {:ok, game.game}
      {:error, _, error, _data} -> {:error, error.errors}
      _ -> {:ok, nil}
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
