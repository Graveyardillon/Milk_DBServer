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
  Atom map to String map
  """
  def atom_map_to_string_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      {Atom.to_string(k), v}
    end)
    |> Map.new()
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
  def create_error_message(error) when is_binary(error) do
    error
  end

  def create_error_message(error) do
    error
    |> Enum.reduce("", fn {key, value}, acc ->
      to_string(key) <> " " <> elem(value, 0) <> ", " <> acc
    end)
  end

  @doc """
  Get ip address
  """
  def get_ip() do
    :inet.getif()
    |> elem(1)
    |> hd()
    |> elem(0)
    |> Tuple.to_list()
    |> Enum.reduce("", fn n, acc ->
      "#{acc}.#{to_string(n)}"
    end)
    |> String.slice(1..1500)
  end

  @doc """
  Get hostname
  """

  def get_hostname() do
    :inet.gethostname()
    |> elem(1)
  end
end
