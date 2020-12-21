defmodule MilkWeb.EntrantControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{Tournaments, Accounts,Ets}
  alias Milk.Tournaments.Entrant

  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }
  @create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }
  @update_attrs %{
    rank: 43
  }
  @invalid_attrs %{rank: nil}

  @tournament_valid_attrs %{
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

  def fixture(:entrant) do
    {:ok, tournament} = fixture(:tournament)

    {:ok, entrant} =
      %{@create_attrs | "tournament_id" => tournament.id, "user_id" => tournament.master_id}
      |> Tournaments.create_entrant()
    entrant
  end
  def fixture(:tournament) do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      %{}
      |> Enum.into(@tournament_valid_attrs)
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()
    end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all entrant", %{conn: conn} do
      conn = get(conn, Routes.entrant_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create entrant" do
    test "renders entrant when data is valid", %{conn: conn} do
      {:ok, tournament} = fixture(:tournament)
      conn = post(conn, Routes.entrant_path(conn, :create), entrant: %{@create_attrs | "tournament_id" => tournament.id, "user_id" => tournament.master_id})
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.entrant_path(conn, :show, id))

      assert %{
               "id" => id,
               "rank" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.entrant_path(conn, :create), entrant: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end

  describe "update entrant" do
    setup [:create_entrant]

    test "renders entrant when data is valid", %{conn: conn, entrant: %Entrant{id: id} = _entrant} do
      conn = put(conn, Routes.entrant_path(conn, :update, id), entrant: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.entrant_path(conn, :show, id))

      assert %{
               "id" => id,
               "rank" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, entrant: entrant} do
      conn = put(conn, Routes.entrant_path(conn, :update, entrant), entrant: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end

  describe "delete entrant" do
    setup [:create_entrant]

    test "deletes chosen entrant", %{conn: conn, entrant: entrant} do
      conn = delete(conn, Routes.entrant_path(conn, :delete), tournament_id: entrant.tournament_id,user_id: entrant.user_id)
      assert response(conn, 200)

      assert_error_sent 404, fn ->
        get(conn, Routes.entrant_path(conn, :show, entrant))
      end
    end
  end

  describe "show entrant's rank" do
    setup [:create_entrant]

    test "renders entrant's rank when data is valid", %{conn: conn,entrant: entrant} do
      conn = get(conn, Routes.entrant_path(conn, :show_rank, entrant.tournament_id, entrant.user_id))
      assert is_integer(json_response(conn, 200)["data"]["rank"])
    end

    test "renders error with invalid tournament_id", %{conn: conn,entrant: entrant} do
      conn = get(conn, Routes.entrant_path(conn, :show_rank, -1, entrant.user_id))
      assert json_response(conn, 200)["error"] == "entrant is not found"
    end

    test "renders error with invalid user_id", %{conn: conn,entrant: entrant} do
      conn = get(conn, Routes.entrant_path(conn, :show_rank, entrant.tournament_id, -1))
      assert json_response(conn, 200)["error"] == "entrant is not found"
    end

    test "renders error when data is invalid", %{conn: conn} do
      conn = get(conn, Routes.entrant_path(conn, :show_rank, -1, -1))
      assert json_response(conn, 200)["error"] == "entrant is not found"
    end
  end

  describe "promote entrant's rank" do
    setup [:create_entrant]

    test "renders entrant's promoted rank with valid data", %{conn: conn, entrant: entrant} do
      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録

      {:ok, matchlist} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Tournaments.generate_matchlist()

      Ets.insert_match_list(matchlist, entrant.tournament_id)

      conn = post(conn, Routes.entrant_path(conn, :promote), tournament_id: entrant.tournament_id, user_id: entrant.user_id)
      assert json_response(conn, 200)["data"]["rank"] == 4
    end

    test "renders error with invalid data(tournament_id)", %{conn: conn, entrant: entrant} do
      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      conn = post(conn, Routes.entrant_path(conn, :promote), tournament_id: -1, user_id: entrant.user_id)
      assert json_response(conn, 200)["error"] == "undefined tournament"
    end

    test "renders error with invalid data(user_id)", %{conn: conn, entrant: entrant} do
      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      conn = post(conn, Routes.entrant_path(conn, :promote), tournament_id: entrant.tournament_id, user_id: -1)
      assert json_response(conn, 200)["error"] == "undefined user"
    end

    test "renders error with invalid data(all)", %{conn: conn, entrant: entrant} do
      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してEtsに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Ets.insert_match_list(entrant.tournament_id)
      assert conn = post(conn, Routes.entrant_path(conn, :promote), tournament_id: -1, user_id: -1)
      assert json_response(conn, 200)["error"] == "undefined user"
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

  defp create_entrant(_) do
    entrant = fixture(:entrant)
    %{entrant: entrant}
  end
end
