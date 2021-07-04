defmodule MilkWeb.TeamControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Tournaments

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get_confirmed_teams" do
    test "get_confirmed_teams works" do

    end
  end
end
