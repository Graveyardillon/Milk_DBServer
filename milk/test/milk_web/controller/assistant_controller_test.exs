defmodule MilkWeb.AssistantControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Tournaments
  alias Milk.Tournaments.Assistant
  alias Milk.Accounts

  @invalid_attrs %{}
  @update_attrs %{}
  @tournament_create_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "master_id" => 42,
    "name" => "some name",
    "type" => 42,
    "join" => "true",
    "url" => "some url"
  }

  defp fixture(:user) do
    {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
    user
  end

  defp fixture(:tournament) do
    {:ok, user} = Accounts.create_user(%{"name" => "myname", "email" => "mye@mail.com", "password" => "Password123"})

    {:ok, tournament} =
      @tournament_create_attrs
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()
    tournament
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all assistant", %{conn: conn} do
      conn = post(conn, Routes.assistant_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create assistant" do
    test "renders assistant when data is valid", %{conn: conn} do
      tournament = fixture(:tournament)
      user = fixture(:user)

      conn = post(conn, Routes.assistant_path(conn, :create), %{"assistant" => %{"tournament_id" => tournament.id, "user_id" => [user.id]}})
      assert %{"id" => id, "create_time" => _, "tournament_id" => _, "update_time" => _, "user_id" => _} = json_response(conn, 200)["data"] |> hd()

      conn = post(conn, Routes.assistant_path(conn, :show, %{"id" => id}))

      assert %{"id" => _id} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_path(conn, :create), %{"assistant" => @invalid_attrs})
      assert %{"data" => _, "error" => _, "result" => false} = json_response(conn, 200)
    end
  end

  describe "update assistant" do
    setup [:create_assistant]

    test "renders assistant when data is valid", %{conn: conn, assistant: %Assistant{id: id} = assistant} do
      conn = put(conn, Routes.assistant_path(conn, :update, assistant), assistant: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.assistant_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, assistant: assistant} do
      conn = put(conn, Routes.assistant_path(conn, :update, assistant), assistant: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete assistant" do
    setup [:create_assistant]

    test "deletes chosen assistant", %{conn: conn, assistant: assistant} do
      conn = delete(conn, Routes.assistant_path(conn, :delete, assistant))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.assistant_path(conn, :show, assistant))
      end
    end
  end

  defp create_assistant(_) do
    assistant = fixture(:assistant)
    %{assistant: assistant}
  end
end
