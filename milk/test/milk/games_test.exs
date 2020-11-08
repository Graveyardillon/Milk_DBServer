defmodule Milk.GamesTest do
  use Milk.DataCase

  alias Milk.Games

  describe "games" do
    alias Milk.Games.Game

    @valid_attrs %{icon_path: "some icon_path", title: "some title"}
    @update_attrs %{icon_path: "some updated icon_path", title: "some updated title"}
    @invalid_attrs %{icon_path: nil, title: nil}

    def game_fixture(attrs \\ %{}) do
      {:ok, game} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Games.create_game()

      game
    end
# fix me
    # test "list_games/0 returns all games" do
    #   game = game_fixture()
    #   assert Games.list_games() == [game]
    # end

    # test "get_game!/1 returns the game with given id" do
    #   game = game_fixture()
    #   assert Games.get_game!(game.id) == game
    # end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %Game{} = game} = Games.create_game(@valid_attrs)
      assert game.icon_path == "some icon_path"
      assert game.title == "some title"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      assert {:ok, %Game{} = game} = Games.update_game(game, @update_attrs)
      assert game.icon_path == "some updated icon_path"
      assert game.title == "some updated title"
    end
# fix me
    # test "update_game/2 with invalid data returns error changeset" do
    #   game = game_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Games.update_game(game, @invalid_attrs)
    #   assert game == Games.get_game!(game.id)
    # end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Games.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Games.change_game(game)
    end
  end
end
