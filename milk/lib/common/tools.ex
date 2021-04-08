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

  def is_all_map_elements_nil?(map) do
    unless is_map(map), do: raise "Argument is not map"

    map
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> (fn x -> length(x) == 0 end).()
  end
end
