defmodule Milk.Accounts.UserReportTest do
  use Milk.DataCase
  alias Milk.Accounts.UserReport

  describe "changeset" do
    test "changeset/2 returns changeset" do
      assert %UserReport{reporter_id: 0, reportee_id: 1}
      |> UserReport.changeset(%{report_type: 0})
    end
  end
end
