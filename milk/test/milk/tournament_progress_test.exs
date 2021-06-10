defmodule Milk.TournamentProgressTest do
  @moduledoc """
  Redisが使えるときのみコメントアウトを解除する
  """
  use Milk.DataCase, async: true
  use Timex

  alias Milk.{
    Accounts,
    TournamentProgress,
    Tournaments
  }

  @valid_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some name",
    "type" => 0,
    "url" => "somesomeurl",
    "master_id" => 1,
    "platform" => 1,
    "is_started" => true
  }
  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }

  @moduletag timeout: :infinity

  defp fixture_user(n) do
    attrs = %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => to_string(n) <> "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => to_string(n) <> "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  defp fixture_tournament(opts \\ []) do
    # FIXME: ここのデフォルト値は本当はfalseのほうがよさそう
    is_started =
      opts[:is_started]
      |> is_nil()
      |> unless do
        opts[:is_started]
      else
        true
      end

    master_id =
      opts[:master_id]
      |> is_nil()
      |> unless do
        opts[:master_id]
      else
        {:ok, user} =
          Accounts.create_user(%{
            "name" => "name",
            "email" => "e@mail.com",
            "password" => "Password123"
          })

        user.id
      end

    {:ok, tournament} =
      @valid_attrs
      |> Map.put("is_started", is_started)
      |> Map.put("master_id", master_id)
      |> Tournaments.create_tournament()

    tournament
  end

  # defp fixture_entrant(opts \\ %{}) do
  #   tournament =
  #     opts["tournament_id"]
  #     |> is_nil()
  #     |> unless do
  #       Tournaments.get_tournament!(opts["tournament_id"])
  #     else
  #       fixture_tournament()
  #     end

  #   user_id =
  #     opts["user_id"]
  #     |> is_nil()
  #     |> unless do
  #       opts["user_id"]
  #     else
  #       tournament.master_id
  #     end

  #   {:ok, entrant} =
  #     %{@entrant_create_attrs | "tournament_id" => tournament.id, "user_id" => user_id}
  #     |> Tournaments.create_entrant()

  #   entrant
  # end

  defp create_entrants(num, tournament_id, result \\ []),
    do: create_entrants(num, tournament_id, result, num)

  defp create_entrants(_num, _tournament_id, result, 0) do
    result
  end

  defp create_entrants(num, tournament_id, result, current) do
    {:ok, user} =
      %{
        "name" => "name" <> to_string(current),
        "email" => "e" <> to_string(current) <> "@mail.com",
        "password" => "Password123"
      }
      |> Accounts.create_user()

    {:ok, entrant} =
      %{
        @entrant_create_attrs
        | "tournament_id" => tournament_id,
          "user_id" => user.id,
          "rank" => num
      }
      |> Tournaments.create_entrant()

    create_entrants(num, tournament_id, result ++ [entrant], current - 1)
  end

  # defp create_entrant(_) do
  #   entrant = fixture_entrant()
  #   %{entrant: entrant}
  # end

  defp start(master_id, tournament_id) do
    Tournaments.start(master_id, tournament_id)

    {:ok, match_list} =
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count =
      Tournaments.get_tournament(tournament_id)
      |> Map.get(:count)

    match_list
    |> Tournaments.initialize_rank(count, tournament_id)

    match_list
    |> TournamentProgress.insert_match_list(tournament_id)

    list_with_fight_result =
      match_list
      |> match_list_with_fight_result()

    lis =
      list_with_fight_result
      |> Tournamex.match_list_to_list()

    Enum.reduce(lis, list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> TournamentProgress.insert_match_list_with_fight_result(tournament_id)
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  describe "match list table" do
    test "insert_match_list/2 works fine" do
      match_list = [[1, 2], 3]
      assert r = TournamentProgress.insert_match_list(match_list, 1)
      assert is_boolean(r)
    end

    test "get_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list(match_list, 2)
      match_list = TournamentProgress.get_match_list(2)
      assert match_list
      assert match_list == [[1, 2], 3]
    end

    test "get_match_list/1 returns data 1 size smaller than past one after deleting a user" do
      tournament = fixture_tournament()
      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      start(tournament.master_id, tournament.id)

      tournament.id
      |> TournamentProgress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      entrants
      |> hd()
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> Accounts.delete()

      tournament.id
      |> TournamentProgress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        if user_id == hd(entrants).user_id do
          refute user_id in entrant_id_list
        else
          assert user_id in entrant_id_list
        end
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants) - 1
          end).()
    end

    test "delete_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list(match_list, 3)
      assert r = TournamentProgress.delete_match_list(3)
      assert is_boolean(r)
    end
  end

  describe "match pending list" do
    test "insert_match_pending_list_table/1 works fine" do
      r = TournamentProgress.insert_match_pending_list_table(1, 1)
      assert r
      assert is_boolean(r)
    end

    test "get_match_pending_list/2" do
      TournamentProgress.insert_match_pending_list_table(1, 2)
      assert {r} = TournamentProgress.get_match_pending_list(1, 2) |> hd()
      assert r == {1, 2}
    end

    test "delete_match_pending_list" do
      TournamentProgress.insert_match_pending_list_table(1, 3)
      assert r = TournamentProgress.delete_match_pending_list(1, 3)
      assert is_boolean(r)
    end
  end

  describe "fight result table" do
    test "insert_fight_result/2 works fine" do
      assert r = TournamentProgress.insert_fight_result_table(1, 1, true)
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine true" do
      TournamentProgress.insert_fight_result_table(1, 2, true)
      assert {_, r} = TournamentProgress.get_fight_result(1, 2) |> hd()
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine false" do
      TournamentProgress.insert_fight_result_table(2, 2, false)
      assert {_, r} = TournamentProgress.get_fight_result(2, 2) |> hd()
      refute r
    end

    test "delete_fight_result/1 works fine" do
      TournamentProgress.insert_fight_result_table(1, 3, true)
      assert r = TournamentProgress.delete_fight_result(1, 3)
      assert is_boolean(r)
    end
  end

  describe "match list with fight result" do
    test "insert_match_list_with_fight_result/2" do
      match_list = [
        [
          %{"user_id" => 1},
          %{"user_id" => 2}
        ],
        %{"user_id" => 3}
      ]

      r = TournamentProgress.insert_match_list_with_fight_result(match_list, 1)
      assert r
      assert is_boolean(r)
    end

    test "get_match_list_with_fight_result/1" do
      match_list = [
        [
          %{"user_id" => 1},
          %{"user_id" => 2}
        ],
        %{"user_id" => 3}
      ]

      TournamentProgress.insert_match_list_with_fight_result(match_list, 2)

      2
      |> TournamentProgress.get_match_list_with_fight_result()
      |> (fn result ->
            result == match_list
          end).()
    end

    test "get_match_list/1 returns data which is renewed after deleting a user" do
      tournament = fixture_tournament()
      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      start(tournament.master_id, tournament.id)

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn bracket ->
        assert is_map(bracket)

        if is_map(bracket) do
          assert bracket["user_id"] in entrant_id_list
          assert bracket["is_loser"] == false
        end
      end)

      entrants
      |> hd()
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> Accounts.delete()

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn bracket ->
        if is_map(bracket) do
          if bracket["user_id"] == hd(entrants).user_id do
            assert bracket["user_id"] in entrant_id_list
            assert bracket["is_loser"]
          else
            assert bracket["user_id"] in entrant_id_list
            assert bracket["is_loser"] == false
          end
        end
      end)
    end

    test "delete_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list_with_fight_result(match_list, 3)
      assert r = TournamentProgress.delete_match_list_with_fight_result(3)
      assert is_boolean(r)
    end
  end

  describe "duplicate users" do
    test "test duplicate user pair" do
      assert TournamentProgress.add_duplicate_user_id(1, 1)
      TournamentProgress.add_duplicate_user_id(1, 2)
      TournamentProgress.add_duplicate_user_id(1, 3)
      assert TournamentProgress.get_duplicate_users(1) == [1, 2, 3]
      assert TournamentProgress.delete_duplicate_user(1, 1)
      assert TournamentProgress.get_duplicate_users(1) == [2, 3]
      assert TournamentProgress.delete_duplicate_users_all(1)
      assert TournamentProgress.get_duplicate_users(1) == []
    end
  end

  # TODO: 検証が不十分なためコメントアウトしておいた
  # describe "absence" do
  #   test "set_timelimit_on_all_entrants/1 works fine" do
  #     tournament = fixture_tournament(is_started: false)
  #     entrants = create_entrants(7, tournament.id)
  #     {:ok, entrant} = Tournaments.create_entrant(%{"user_id" => tournament.master_id, "tournament_id" => tournament.id})
  #     entrants = entrants ++ [entrant]
  #     start(tournament.master_id, tournament.id)

  #     [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
  #     TournamentProgress.set_time_limit_on_all_entrants(match_list, tournament.id)
  #     [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
  #     refute Tournaments.has_lost?(match_list, tournament.master_id)

  #     5
  #     |> Kernel.*(61)
  #     |> Kernel.*(1000)
  #     |> Process.sleep()

  #     [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
  #     assert Tournaments.has_lost?(match_list, tournament.master_id)

  #     Enum.each(entrants, fn entrant ->
  #       entrant
  #       |> Map.get(:user_id)
  #       |> TournamentProgress.get_lost_pid(tournament.id)
  #       |> (fn bool ->
  #         assert bool
  #       end).()
  #     end)
  #   end

  #   test "cancel_lose/2 works fine" do
  #     tournament = fixture_tournament(is_started: false)
  #     entrants = create_entrants(7, tournament.id)
  #     {:ok, entrant} = Tournaments.create_entrant(%{"user_id" => tournament.master_id, "tournament_id" => tournament.id})
  #     entrants = entrants ++ [entrant]
  #     start(tournament.master_id, tournament.id)

  #     [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
  #     TournamentProgress.set_time_limit_on_all_entrants(match_list, tournament.id)
  #     TournamentProgress.cancel_lose(tournament.id, tournament.master_id)

  #     5
  #     |> Kernel.*(61)
  #     |> Kernel.*(1000)
  #     |> Process.sleep()

  #     [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
  #     refute Tournaments.has_lost?(match_list, tournament.master_id)
  #   end
  # end

  describe "score table" do
    test "insert_score/3 and get_score/2" do
      tid = 1
      uid = 1
      score = 13
      TournamentProgress.insert_score(tid, uid, score)

      assert TournamentProgress.get_score(tid, uid) == score
    end
  end

  describe "get single tournament match logs" do
    test "works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)
      tournament = fixture_tournament()
      str = "just str"

      Map.new()
      |> Map.put("tournament_id", tournament.id)
      |> Map.put("winner_id", user1.id)
      |> Map.put("loser_id", user2.id)
      |> Map.put("match_list_str", str)
      |> TournamentProgress.create_single_tournament_match_log()

      TournamentProgress.get_single_tournament_match_logs(tournament.id, user1.id)
      |> Enum.map(fn log ->
        assert log.tournament_id == tournament.id
        assert log.winner_id == user1.id
        assert log.loser_id == user2.id
        assert log.match_list_str == str
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()

      TournamentProgress.get_single_tournament_match_logs(tournament.id, user2.id)
      |> Enum.map(fn log ->
        assert log.tournament_id == tournament.id
        assert log.winner_id == user1.id
        assert log.loser_id == user2.id
        assert log.match_list_str == str
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "create single tournament match log" do
    test "JUST works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)
      tournament = fixture_tournament()
      str = "just str"

      id =
        %{}
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("winner_id", user1.id)
        |> Map.put("loser_id", user2.id)
        |> Map.put("match_list_str", str)
        |> TournamentProgress.create_single_tournament_match_log()
        |> (fn result ->
              assert {:ok, log} = result
              assert log.tournament_id == tournament.id
              assert log.winner_id == user1.id
              assert log.loser_id == user2.id
              assert log.match_list_str == str
              log.id
            end).()

      TournamentProgress.get_single_tournament_match_log(id)
      |> (fn log ->
            assert log.tournament_id == tournament.id
            assert log.winner_id == user1.id
            assert log.loser_id == user2.id
            assert log.match_list_str == str
            log.id
          end).()
    end
  end

  describe "create and get match list with fight result log" do
    test "just works" do
      match_list = [[1, 2], [3, 4]]
      tournament_id = 1

      str = inspect(match_list, charlists: false)

      %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
      |> TournamentProgress.create_match_list_with_fight_result_log()
      |> (fn log ->
            assert {:ok, log} = log
            assert log.tournament_id == tournament_id
            assert log.match_list_with_fight_result_str == str
          end).()
    end
  end
end
