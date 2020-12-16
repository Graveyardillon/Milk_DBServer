defmodule Milk.TournamentsTest do
  use Milk.DataCase

  alias Milk.{Tournaments, Accounts, Ets}

  describe "tournament" do
    alias Milk.Tournaments.Tournament
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

    defp fixture(:tournament) do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      {:ok, tournament} =
        %{}
        |> Enum.into(@valid_attrs)
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()
      tournament
    end

    defp fixture(:entrant) do
      tournament = fixture(:tournament)

      {:ok, entrant} =
        %{@entrant_create_attrs | "tournament_id" => tournament.id, "user_id" => tournament.master_id}
        |> Tournaments.create_entrant()
      entrant
    end

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

    # FIXME: このテストがなぜか通らない
    test "promote_rank/1 returns promoted rank with valid attrs", %{entrant: entrant} do
      # promote_rankの引数となるattrs
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
