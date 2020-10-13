defmodule MilkWeb.AssistantControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Tournaments
  alias Milk.Tournaments.Assistant

  @create_attrs %{

  }
  @update_attrs %{

  }
  @invalid_attrs %{}

  def fixture(:assistant) do
    {:ok, assistant} = Tournaments.create_assistant(@create_attrs)
    assistant
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all assistant", %{conn: conn} do
      conn = get(conn, Routes.assistant_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create assistant" do
    test "renders assistant when data is valid", %{conn: conn} do
      conn = post(conn, Routes.assistant_path(conn, :create), assistant: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.assistant_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_path(conn, :create), assistant: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
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
