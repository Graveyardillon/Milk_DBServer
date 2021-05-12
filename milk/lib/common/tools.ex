defmodule Common.Tools do
  @moduledoc """
  Common tool functions.
  """

  @doc """
  string to integer if possible.
  """
  def to_integer_as_needed(data) do
    if is_binary(data) do
      String.to_integer(data)
    else
      data
    end
  end

  @doc """
  Checks if all map elements are nil
  """
  def is_all_map_elements_nil?(map) do
    unless is_map(map), do: raise("Argument is not map")

    map
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> (fn x -> length(x) == 0 end).()
  end

  @doc """
  Create error message
  """
  def create_error_message(error) do
    error
    |> Enum.reduce("", fn {key, value}, acc ->
      to_string(key) <> " " <> elem(value, 0) <> ", " <> acc
    end)
  end
end
