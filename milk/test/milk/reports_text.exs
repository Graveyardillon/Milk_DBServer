defmodule Milk.ReportsTest do
  use Milk.DataCase

  alias Milk.{
    Accounts,
    Reports
  }

  defp fixture_user(n \\ 0) do
    attrs = %{"icon_path" => "some icon_path", "language" => "some language", "name" => to_string(n)<>"some name", "notification_number" => 42, "point" => 42, "email" => to_string(n)<>"some@email.com", "logout_fl" => true, "password" => "S1ome password"}
    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  describe "create" do
    test "works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      report_attrs = %{
        "reporter" => user1.id,
        "reportee" => user2.id,
        "report_types" => [0]
      }
      assert {:ok, report} = Reports.create(report_attrs)
    end
  end
end
