defmodule Common.ToolsTest do
  @moduledoc """
  Test for tools.
  """
  use Milk.DataCase

  import Common.Tools

  alias Common.Tools

  describe "atom map to string map" do
    test "works" do
      assert Tools.atom_map_to_string_map(%{a: 1}) == %{"a" => 1}
      assert Tools.atom_map_to_string_map(%{"a" => 1}) == %{"a" => 1}
    end
  end

  describe "get_closest_num_of_multiple" do
    test "works" do
      assert Tools.get_closest_num_of_multiple(50, 8) === 48
      assert Tools.get_closest_num_of_multiple(24, 3) === 24
      assert Tools.get_closest_num_of_multiple(0, 0)  === 0
    end
  end

  describe "get_hostname" do
    test "get_hostname works" do
      refute is_nil(Tools.get_hostname())
    end
  end

  describe "get_ip" do
    test "get_ip works" do
      ip = Tools.get_ip()
      assert is_binary(ip)
    end
  end

  describe "is_power_of_two?" do
    test "with 0", do: refute is_power_of_two?(0)
    test "with 1", do: assert is_power_of_two?(1)
    test "with 2", do: assert is_power_of_two?(2)
    test "with 3", do: refute is_power_of_two?(3)
    test "with 4", do: assert is_power_of_two?(4)
    test "with 1024", do: assert is_power_of_two?(1024)
  end

  describe "is_all_map_elements_nil?/1" do
    @valid_data_1 %{"a" => nil, "b" => nil, "c" => nil}
    @valid_data_2 %{"a" => 2, "b" => 3, "c" => nil}
    @invalid_data_1 "Hello"
    @invalid_data_2 42

    test "is_map_element_nil?/1 works fine with valid data" do
      assert Tools.is_all_map_elements_nil?(@valid_data_1)
      refute Tools.is_all_map_elements_nil?(@valid_data_2)
    end

    test "is_map_element_nil?/1 does not work with invalid data" do
      refute Tools.is_all_map_elements_nil?(@invalid_data_1)
      refute Tools.is_all_map_elements_nil?(@invalid_data_2)
    end
  end

  describe "to_integer_as_needed/1" do
    @valid_data "5"
    @invalid_data "Hello"

    test "to_integer_as_needed/1 works fine with valid data" do
      assert Tools.to_integer_as_needed(@valid_data) == 5
    end

    test "to_integer_as_needed1 does not work with invalied data" do
      assert catch_error(Tools.to_integer_as_needed(@invalid_data)) == :badarg
    end
  end
end
