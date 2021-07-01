defmodule Common.ToolsTest do
  use Milk.DataCase

  alias Common.Tools

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

  describe "is_map_element_nil?/1" do
    @valid_data_1 %{"a" => nil, "b" => nil, "c" => nil}
    @valid_data_2 %{"a" => 2, "b" => 3, "c" => nil}
    @invalid_data_1 "Hello"
    @invalid_data_2 42

    test "is_map_element_nil?/1 works fine with valid data" do
      assert Tools.is_all_map_elements_nil?(@valid_data_1)
      refute Tools.is_all_map_elements_nil?(@valid_data_2)
    end

    test "is_map_element_nil?/1 does not work with invalid data" do
      assert catch_error(Tools.is_all_map_elements_nil?(@invalid_data_1)) == %RuntimeError{
               message: "Argument is not map"
             }

      assert catch_error(Tools.is_all_map_elements_nil?(@invalid_data_2)) == %RuntimeError{
               message: "Argument is not map"
             }
    end
  end

  describe "get_ip" do
    test "get_ip works" do
      ip = Tools.get_ip()
      assert is_binary(ip)
    end
  end

  describe "get_hostname" do
    test "get_hostname works" do
      Tools.get_hostname()
    end
  end
end
