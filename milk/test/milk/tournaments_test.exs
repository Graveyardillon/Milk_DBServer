defmodule Milk.TournamentsTest do
  use Milk.DataCase

  alias Milk.Tournaments
  alias Milk.Accounts

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
      "platform" => 1
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

  describe "entrant" do
    test "get_rank/2 returns entrant's rank when data is valid" do
      entrant = fixture(:entrant)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == entrant.rank
    end

    test "get_rank/2 returns error with invalid tournament_id" do
      entrant = fixture(:entrant)
      assert Tournaments.get_rank(-1, entrant.user_id) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid user_id" do
      entrant = fixture(:entrant)
      assert Tournaments.get_rank(entrant.tournament_id, -1) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid params" do
      assert Tournaments.get_rank(-1, -1) == {:error, "entrant is not found"}
    end
  end
end
