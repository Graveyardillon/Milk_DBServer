defmodule Milk.ReportsTest do
  use Milk.DataCase

  alias Milk.{
    Accounts,
    Reports,
    Tournaments
  }

  @valid_tournament_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some name",
    "type" => 0,
    "url" => "somesomeurl",
    "password" => "passwd",
    "master_id" => 1,
    "platform_id" => 1,
    "is_started" => true
  }

  defp fixture_user(n \\ 0) do
    attrs = %{"icon_path" => "some icon_path", "language" => "some language", "name" => to_string(n)<>"some name", "notification_number" => 42, "point" => 42, "email" => to_string(n)<>"some@email.com", "logout_fl" => true, "password" => "S1ome password"}
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
        {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
        user.id
      end

    {:ok, tournament} =
      @valid_tournament_attrs
      |> Map.put("is_started", is_started)
      |> Map.put("master_id", master_id)
      |> Tournaments.create_tournament()
    tournament
  end

  describe "create user report" do
    test "works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      report_attrs = %{
        "reporter" => user1.id,
        "reportee" => user2.id,
        "report_types" => [0]
      }
      assert {:ok, report} = Reports.create_user_report(report_attrs)
    end
  end

  describe "create tournament report" do
    test "works" do
      tournament = fixture_tournament()
      user = fixture_user()

      report_attrs = %{
        "reporter_id" => user.id,
        "tournament_id" => tournament.id
      }
      Reports.create_tournament_report(report_attrs)
      |> IO.inspect()
    end
  end
end
