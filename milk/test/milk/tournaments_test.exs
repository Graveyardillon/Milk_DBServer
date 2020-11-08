defmodule Milk.TournamentsTest do
  use Milk.DataCase

  alias Milk.Tournaments
  alias Milk.Accounts
  alias Milk.Accounts.User

  describe "tournament" do
    alias Milk.Tournaments.Tournament
    # 外部キーが二つ以上の場合は %{"capacity" => 42} のようにしなければいけない
    @valid_attrs %{
      capacity: 42, 
      deadline: "2010-04-17T14:00:00Z", 
      description: "some description", 
      event_date: "2010-04-17T14:00:00Z", 
      name: "some name", 
      type: 0, 
      url: "some url"
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
      capacity: nil, 
      deadline: nil, 
      description: nil, 
      event_date: nil, 
      name: nil, 
      type: nil, 
      url: nil
    }

    def tournament_fixture(attrs \\ %{}) do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      tournament =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:master_id, user.id)
        |> Tournaments.create_tournament()

      tournament
    end
    #fix me
    # test "list_tournament/0 returns all tournament" do
    #   {:ok,tournament} = tournament_fixture()
    #   assert Tournaments.list_tournament() == [tournament]
    # end

    test "create_tournament/1 with valid data creates a tournament" do
      {:ok, tournament} = tournament_fixture()
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
      {:ok, tournament} = tournament_fixture()
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
      {:ok, tournament} = tournament_fixture()
      assert {:error, _} = Tournaments.update_tournament(tournament, @invalid_attrs)
      # fix me
      # assert tournament == Tournaments.get_tournament!(tournament.id)
    end
  end
end
