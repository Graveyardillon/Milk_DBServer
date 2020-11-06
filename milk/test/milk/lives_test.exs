defmodule Milk.LivesTest do
  use Milk.DataCase

  alias Milk.Lives

  describe "lives" do
    alias Milk.Lives.Live

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def live_fixture(attrs \\ %{}) do
      {:ok, live} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Lives.create_live()

      live
    end
    #fix me
    # test "list_lives/0 returns all lives" do
    #   live = live_fixture()
    #   assert Lives.list_lives() == [live]
    # end
    #fix me
    # test "get_live!/1 returns the live with given id" do
    #   live = live_fixture()
    #   assert Lives.get_live!(live.id) == live
    # end

    test "create_live/1 with valid data creates a live" do
      assert {:ok, %Live{} = live} = Lives.create_live(@valid_attrs)
      assert live.name == "some name"
    end

    test "create_live/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lives.create_live(@invalid_attrs)
    end

    test "update_live/2 with valid data updates the live" do
      live = live_fixture()
      assert {:ok, %Live{} = live} = Lives.update_live(live, @update_attrs)
      assert live.name == "some updated name"
    end
    #fix me
    # test "update_live/2 with invalid data returns error changeset" do
    #   live = live_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Lives.update_live(live, @invalid_attrs)
    #   assert live == Lives.get_live!(live.id)
    # end

    test "delete_live/1 deletes the live" do
      live = live_fixture()
      assert {:ok, %Live{}} = Lives.delete_live(live)
      assert_raise Ecto.NoResultsError, fn -> Lives.get_live!(live.id) end
    end

    test "change_live/1 returns a live changeset" do
      live = live_fixture()
      assert %Ecto.Changeset{} = Lives.change_live(live)
    end
  end
end
