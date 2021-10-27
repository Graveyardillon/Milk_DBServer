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
  @spec create_error_message(any()) :: String.t()
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
  @spec into_ok_tuple(any()) :: {:ok, any()}
  def into_ok_tuple(data), do: {:ok, data}

  @doc """
  Turn into tuple {:error, data}
  """
  @spec into_error_tuple(any()) :: {:error, any()}
  def into_error_tuple(data), do: {:error, data}

  @doc """
  Checks if all map elements are nil
  """
  @spec is_all_map_elements_nil?(map()) :: boolean()
  def is_all_map_elements_nil?(data) when not is_map(data), do: false
  def is_all_map_elements_nil?(map) do
    map
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Enum.empty?()
  end

  @spec is_power_of_two?(integer()) :: boolean()
  def is_power_of_two?(num), do: num != 0 and num && num - 1 === 0

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
