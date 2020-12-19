defmodule Milk.TournamentsTest do
  use Milk.DataCase

  alias Milk.{Tournaments, Accounts, Ets, Relations, Games}
  alias Milk.Tournaments.{Tournament, Entrant}
  alias Milk.Accounts.User

  # 外部キーが二つ以上の場合は %{"capacity" => 42} のようにしなければいけない
  @valid_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some name",
    "type" => 0,
    "url" => "some url",
    "master_id" => 1,
    "platform" => 1,
    "is_started" => true
  }
  @update_attrs %{
    capacity: 43,
    deadline: "2011-05-18T15:01:01Z",
    description: "some updated description",
    event_date: "2011-05-18T15:01:01Z",
    name: "some updated name",
    type: 43,
    url: "some updated url"
  }
  @invalid_attrs %{
    "capacity" => nil,
    "deadline" => nil,
    "description" => nil,
    "event_date" => nil,
    "name" => nil,
    "type" => nil,
    "url" => nil,
    "master_id" => 1,
    "platform" => 1
  }
  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }
  @invalid_entrant_create_attrs %{
    "user_id" => nil,
    "tournament_id" => nil
  }

  defp fixture(:tournament) do
    {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
    {:ok, tournament} =
      %{}
      |> Enum.into(@valid_attrs)
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()
    tournament
  end

  defp fixture(:tournament, :is_not_started) do
    {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
    {:ok, tournament} =
      %{}
      |> Enum.into(@valid_attrs)
      |> Map.put("master_id", user.id)
      |> Map.put("is_started", false)
      |> Tournaments.create_tournament()
    tournament
  end

  defp fixture(:game) do
    {:ok, game} = Games.create_game(%{"title" => "Test Game"})
    game
  end

  defp fixture(:user) do
    {:ok, user} = Accounts.create_user(%{"name" => "name1", "email" => "e1@mail.com", "password" => "Password123"})
    user
  end

  defp fixture(:entrant) do
    tournament = fixture(:tournament)

    {:ok, entrant} =
      %{@entrant_create_attrs | "tournament_id" => tournament.id, "user_id" => tournament.master_id}
      |> Tournaments.create_entrant()
    entrant
  end

  describe "get tournament" do
    test "list_tournament/0 returns all tournament" do
      _ = fixture(:tournament)
      refute length(Tournaments.list_tournament()) == 0
    end

    test "get_tournaments_by_master_id/1 returns tournaments of a user" do
      tournament = fixture(:tournament)
      refute length(Tournaments.get_tournaments_by_master_id(tournament.master_id)) == 0
    end

    test "get_tournaments_by_master_id/1 fails to return tournaments of a user" do
      user = fixture(:user)
      _tournament = fixture(:tournament)
      assert length(Tournaments.get_tournaments_by_master_id(user.id)) == 0
    end

    test "get_ongoing_tournaments_by_master_id/1 fails to return user's ongoing tournaments" do
      tournament = fixture(:tournament)
      assert length(Tournaments.get_ongoing_tournaments_by_master_id(tournament.master_id)) == 0
    end

    test "get_tournament/1 with valid data works fine" do
      tournament = fixture(:tournament)
      assert %Tournament{} = obtained_tournament = Tournaments.get_tournament(tournament.id)
      assert obtained_tournament.id == tournament.id
    end

    test "get_tournament!/1 with valid data works fine" do
      tournament = fixture(:tournament)
      assert %Tournament{} = obtained_tournament = Tournaments.get_tournament!(tournament.id)
      assert obtained_tournament.id == tournament.id
    end

    test "get_participating_tournaments!/1 with valid data works fine" do
      entrant = fixture(:entrant)
      _tournament = Tournaments.get_tournament(entrant.tournament_id)

      assert tournaments = Tournaments.get_participating_tournaments!(entrant.user_id)
      assert is_list(tournaments)
      Enum.each(tournaments, fn tournament ->
        assert %Tournament{} = tournament
      end)
    end

    test "get_masters/1 with valid data works fine" do
      tournament = fixture(:tournament)

      assert users = Tournaments.get_masters(tournament.id)
      assert is_list(users)
      Enum.each(users, fn user ->
        assert %User{} = user
      end)
    end
  end

  describe "create tournament" do
    test "create_tournament/1 with valid data creates a tournament" do
      tournament = fixture(:tournament)
      assert tournament.capacity == 42
      assert tournament.deadline == "2010-04-17T14:00:00Z"
      assert tournament.description == "some description"
      assert tournament.event_date == "2010-04-17T14:00:00Z"
      assert tournament.name == "some name"
      assert tournament.type == 0
      assert tournament.url == "some url"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, _} = Tournaments.create_tournament(@invalid_attrs)
    end
  end

  describe "update tournament" do
    test "update_tournament/2 with valid data updates the tournament" do
      tournament = fixture(:tournament)
      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, @update_attrs)
      assert tournament.capacity == 43
      assert tournament.deadline == "2011-05-18T15:01:01Z"
      assert tournament.description == "some updated description"
      assert tournament.event_date == "2011-05-18T15:01:01Z"
      assert tournament.name == "some updated name"
      assert tournament.type == 43
      assert tournament.url == "some updated url"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = fixture(:tournament)
      assert {:error, _} = Tournaments.update_tournament(tournament, @invalid_attrs)
    end
  end

  describe "delete tournament" do
    test "delete_tournament/1 of Tournament structure works fine with a valid data" do
      tournament = fixture(:tournament)
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.get_tournament(tournament.id)
    end

    test "delete_tournament/1 of map works fine with a valid data" do
      user = fixture(:user)
      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.get_tournament(tournament.id)
    end

    test "delete_tournament/1 of id works fine with a valid data" do
      tournament = fixture(:tournament)
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament.id)
      refute Tournaments.get_tournament(tournament.id)
    end
  end

  describe "home" do
    @home_attrs %{
      deadline: "2031-05-18T15:01:01Z",
      event_date: "2031-05-18T15:01:01Z"
    }

    test "home_tournament()/0 returns tournaments for home screen" do
      tournament = fixture(:tournament)
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)
      refute length(Tournaments.home_tournament()) == 0
    end

    test "home_tournament_fav/1 returns tournaments which is filtered by favorite users for home screen" do
      user1 = fixture(:user)
      tournament = fixture(:tournament)
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)
      Relations.create_relation(%{"follower_id" => user1.id, "followee_id" => tournament.master_id})

      refute length(Tournaments.home_tournament_fav(user1.id)) == 0
    end

    test "home_tournament_fav/1 fails to return tournaments which is filtered by favorite users for home screen" do
      tournament = fixture(:tournament)
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)
      assert length(Tournaments.home_tournament_fav(tournament.master_id)) == 0
    end

    test "home_tournament_plan/1 returns user's tournaments" do
      tournament = fixture(:tournament)
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)
      refute length(Tournaments.home_tournament_plan(tournament.master_id)) == 0
    end

    test "home_tournament_plan/1 fails to return user's tournaments" do
      tournament = fixture(:tournament)
      assert length(Tournaments.home_tournament_plan(tournament.master_id)) == 0
    end
  end

  describe "game" do
    test "game_tournament/1 returns game of the tournament" do
      game = fixture(:game)
      user = fixture(:user)

      @valid_attrs
      |> Map.put("game_id", game.id)
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()

      assert tournaments = Tournaments.game_tournament(%{"game_id" => game.id})
      assert is_list(tournaments)
      Enum.each(tournaments, fn tournament ->
        assert %Tournament{} = tournament
      end)
    end
  end

  describe "get entrant" do
    setup [:create_entrant]

    test "list_entrant/0 works fine" do
      assert entrants = Tournaments.list_entrant()
      assert is_list(entrants)
      Enum.each(entrants, fn entrant ->
        assert %Entrant{} = entrant
      end)
    end

    test "get_entrant!/1 works fine with a valid data", %{entrant: entrant} do
      assert %Entrant{} = obtained_entrant = Tournaments.get_entrant!(entrant.id)
      assert obtained_entrant.id == entrant.id
    end

    test "get_entrants/1 works fine with a valid data", %{entrant: entrant} do
      num = 7
      create_entrants(num, entrant.tournament_id)
      assert entrants = Tournaments.get_entrants(entrant.tournament_id)
      assert is_list(entrants)
      Enum.each(entrants, fn entrant ->
        assert %Entrant{} = entrant
      end)
    end
  end

  describe "create entrant" do
    test "create_entrant/1 with a valid data works fine" do
      user = fixture(:user)
      tournament = fixture(:tournament)
      {:ok, entrant} =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)
        |> Tournaments.create_entrant()

      assert entrant.user_id == user.id
    end

    test "create_entrant/1 with an invalid data does not work" do
      assert {:error, _} = Tournaments.create_entrant(@invalid_entrant_create_attrs)
    end
  end

  describe "update entrant" do
    setup [:create_entrant]

    test "update_entrant/2 works fine with a valid data", %{entrant: entrant} do
      update_attrs = %{"rank" => 1}
      assert {:ok, _entrant} = Tournaments.update_entrant(entrant, update_attrs)
    end
  end

  describe "delete entrant" do
    setup [:create_entrant]

    test "delete_entrant/2 works fine with a valid data", %{entrant: entrant} do
      assert {:ok, _entrant} = Tournaments.delete_entrant(entrant.tournament_id, entrant.user_id)
      assert %Ecto.NoResultsError{} = catch_error(Tournaments.get_entrant!(entrant.id))
    end

    test "delete_entrant/1 works fine with a valid data", %{entrant: entrant} do
      assert {:ok, _entrant} = Tournaments.delete_entrant(entrant)
      assert %Ecto.NoResultsError{} = catch_error(Tournaments.get_entrant!(entrant.id))
    end
  end

  describe "delete loser" do
    test "delete_loser/2 works fine with a valid data of 4 players" do
      list = [[1, 2], [3, 4]]
      assert Tournaments.delete_loser(list, 1) == [2, [3, 4]]
      assert Tournaments.delete_loser(list, [1]) == [2, [3, 4]]
      assert Tournaments.delete_loser(list, 2) == [1, [3, 4]]
      assert Tournaments.delete_loser(list, [2]) == [1, [3, 4]]
      assert Tournaments.delete_loser(list, 3) == [[1, 2], 4]
      assert Tournaments.delete_loser(list, [3]) == [[1, 2], 4]
      assert Tournaments.delete_loser(list, 4) == [[1, 2], 3]
      assert Tournaments.delete_loser(list, [4]) == [[1, 2], 3]
    end

    test "delete_loser/2 works fine with a valid data of 3 players" do
      list = [[1, 2], 3]

      assert Tournaments.delete_loser(list, 1) == [2, 3]
      assert Tournaments.delete_loser(list, [1]) == [2, 3]
      assert Tournaments.delete_loser(list, 2) == [1, 3]
      assert Tournaments.delete_loser(list, [2]) == [1, 3]
      #assert Tournaments.delete_loser(list, 3) == [1, 2]
      assert Tournaments.delete_loser(list, [3]) == [1, 2]
    end
  end

  describe "tournament flow functions" do
    setup [:create_tournament_for_flow]

    test "start/2 with valid data works fine", %{tournament: tournament} do
      assert {:ok, _tournament} = Tournaments.start(tournament.master_id, tournament.id)
      assert {:error, _} = Tournaments.start(tournament.master_id, tournament.id)
    end

    test "start/2 with invalid data does not work", %{tournament: _tournament} do
      assert {:error, _tournament} = Tournaments.start(nil, nil)
    end

    test "generate_matchlist/1 with valid data works fine", %{tournament: _tournament} do
      data = [1, 2, 3, 4, 5, 6]
      assert {:ok, matchlist} = Tournaments.generate_matchlist(data)
      assert is_list(matchlist)
    end

    test "generate_matchlist/1 with invalid integer data does not work", %{tournament: _tournament} do
      data = 1
      assert {:error, _} = Tournaments.generate_matchlist(data)
    end

    test "generate_matchlist/1 with invalid map data does not work", %{tournament: _tournament} do
      data = %{a: 1, b: 2, c: 3}
      assert {:error, _} = Tournaments.generate_matchlist(data)
    end

    test "find_match/3 with valid data works fine" do
      data = [1, 2, 3, 4, 5, 6]
      {:ok, matchlist} = Tournaments.generate_matchlist(data)
      assert match = Tournaments.find_match(matchlist, 1)
      assert is_list(match)
    end

    test "find_match/3 with invalid data does not work" do
      invalid_data = 3
      assert catch_error(Tournaments.find_match(invalid_data, 3)) == %Protocol.UndefinedError{description: "", protocol: Enumerable, value: 3}
    end

    test "get_opponent/2 with valid data works fine", %{tournament: tournament} do
      entrants = create_entrants(6, tournament.id)
      id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      integer_input = Enum.slice(id_list, 0..1)
      list_input = [hd(id_list)] ++ [Enum.slice(id_list, 1..2)]

      assert {:ok, opponent} = Tournaments.get_opponent(integer_input, hd(id_list))
      assert opponent["id"] == integer_input |> tl() |> hd()
      assert {:wait, nil} = Tournaments.get_opponent(list_input, hd(id_list))
    end

    test "get_opponent with invalid data does not work", %{tournament: _tournament} do

    end
  end

  describe "get entrant's rank" do
    setup [:create_entrant]

    test "get_rank/2 returns entrant's rank when data is valid", %{entrant: entrant} do
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == entrant.rank
    end

    test "get_rank/2 returns error with invalid tournament_id", %{entrant: entrant} do
      assert Tournaments.get_rank(-1, entrant.user_id) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid user_id", %{entrant: entrant} do
      assert Tournaments.get_rank(entrant.tournament_id, -1) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid params" do
      assert Tournaments.get_rank(-1, -1) == {:error, "entrant is not found"}
    end
  end

  describe "promote_rank" do
    setup [:create_entrant]

    test "promote_rank/1 returns promoted rank with valid attrs", %{entrant: entrant} do
      attrs =
        %{
          "tournament_id" => entrant.tournament_id,
          "user_id" => entrant.user_id
        }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      {_, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Tournaments.generate_matchlist()

      Ets.insert_match_list(match_list, entrant.tournament_id)
      # assertフェーズ
      assert {:ok, promoted} = Tournaments.promote_rank(attrs)
      # assert promoted.user_id  == entrant.user_id
      # assert promoted.rank == 4
    end

    test "promote_rank/1 returns error with invalid attrs(tournament_id)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs =
        %{
          "tournament_id" => -1,
          "user_id" => entrant.user_id
        }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      # assertフェーズ
      assert {:error, "undefined tournament"} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(user_id)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs =
        %{
          "tournament_id" => entrant.tournament_id,
          "user_id" => -1
        }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      # assertフェーズ
      assert {:error, "undefined user"} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(all)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs =
        %{
          "tournament_id" => -1,
          "user_id" => -1
        }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      # assertフェーズ
      assert {:error, "undefined user"} = Tournaments.promote_rank(attrs)
    end
  end

  defp create_tournament_for_flow(_) do
    tournament = fixture(:tournament, :is_not_started)
    %{tournament: tournament}
  end

  # 複数の参加者作成用関数
  defp create_entrants(num, tournament_id, result \\ []), do: create_entrants(num, tournament_id, result, num)
  defp create_entrants(_num, _tournament_id, result, 0) do
    result
  end

  defp create_entrants(num, tournament_id, result, current) do
    {:ok, user} =
      %{"name" => "name" <> to_string(current), "email" => "e" <> to_string(current) <> "@mail.com", "password" => "Password123"}
      |> Accounts.create_user()
    {:ok, entrant} =
      %{@entrant_create_attrs | "tournament_id" => tournament_id, "user_id" => user.id, "rank" => num}
      |> Tournaments.create_entrant()
    create_entrants(num, tournament_id, (result ++ [entrant]), current - 1)
  end

  # setup用
  defp create_entrant(_) do
    entrant = fixture(:entrant)
    %{entrant: entrant}
  end
end
