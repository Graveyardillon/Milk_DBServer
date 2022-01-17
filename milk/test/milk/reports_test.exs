defmodule Milk.ReportsTest do
  @moduledoc """
  通報機能に関するテスト
  """

  use Milk.DataCase
  use Common.Fixtures

  alias Milk.Reports

  describe "create user report" do
    test "works" do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)

      report_attrs = %{
        "reporter" => user1.id,
        "reportee" => user2.id,
        "report_types" => [0]
      }

      assert {:ok, _} = Reports.create_user_report(report_attrs)
    end
  end

  describe "create tournament report" do
    test "works" do
      tournament = fixture_tournament()
      user = fixture_user()

      report_attrs = %{
        "reporter_id" => user.id,
        "report_type" => 1,
        "tournament_id" => tournament.id
      }

      assert {:ok, report} = Reports.create_tournament_report(report_attrs)
      assert report.reporter_id == report_attrs["reporter_id"]
      assert report.report_type == report_attrs["report_type"]
      assert report.capacity == tournament.capacity
      assert report.description == tournament.description
      assert report.name == tournament.name
      assert report.url == tournament.url
      # assert report.thumbnail_path == tournament.thumbnail_path
      assert report.count == tournament.count
      assert report.game_name == tournament.game_name
    end
  end
end
