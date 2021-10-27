defmodule Common.Tools do
  @moduledoc """
  Common tool functions.
  """

  @doc """
  Atom map to String map
  """
  def atom_map_to_string_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      if is_atom(k) do
        {Atom.to_string(k), v}
      else
        {k, v}
      end
    end)
    |> Map.new()
  end

  @doc """
  Create error message
  """
  def create_error_message(error) when is_binary(error), do: error
  def create_error_message(error) do
    Enum.reduce(error, "", fn {key, value}, acc ->
      to_string(key) <> " " <> elem(value, 0) <> ", " <> acc
    end)
  end

  @doc """
  Get hostname
  """
  def get_hostname() do
    :inet.gethostname()
    |> elem(1)
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
  Turn into tuple {:ok, data}
  """
  def into_ok_tuple(data), do: {:ok, data}

  @doc """
  Turn into tuple {:error, data}
  """
  def into_error_tuple(data), do: {:error, data}

  @doc """
  Checks if all map elements are nil
  """
  def is_all_map_elements_nil?(map) do
    unless is_map(map), do: raise("Argument is not map")

    map
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> (fn x -> x == [] end).()
  end

  @doc """
  String to json map if possible.
  """
  @spec parse_json_string_as_needed!(any()) :: any()
  def parse_json_string_as_needed!(data) when is_binary(data), do: Poison.decode!(data)
  def parse_json_string_as_needed!(data), do: data

  @doc """
  String to integer if possible.
  """
  @spec to_integer_as_needed(String.t() | integer()) :: integer()
  def to_integer_as_needed(data) when is_binary(data), do: String.to_integer(data)
  def to_integer_as_needed(data), do: data
end
