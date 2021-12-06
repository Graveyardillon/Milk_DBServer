defmodule Milk.EctoDate do
  use Ecto.Type

  def type, do: :utc_datetime_usec

  def cast(%DateTime{} = date) do
    {:ok, date}
  end

  def cast(date) when is_bitstring(date) do
    {:ok, date}
  end

  def cast(_) do
    :error
  end

  def load(%DateTime{} = date) do
    Calendar.DateTime.shift_zone(date, "Asia/Tokyo")
  end

  def load(_) do
    :error
  end

  def dump(%DateTime{} = date) do
    if String.contains?(date.time_zone, "UTC") do
      {:ok, date}
    else
      Calendar.DateTime.shift_zone(date, "Etc/UTC")
    end
  end

  def dump(date) when is_bitstring(date) do
    case DateTime.from_iso8601(date) do
      {:ok, time, _} -> {:ok, time}
      _              -> {:ok, DateTime.utc_now()}
    end
  end
  def dump(_), do: {:ok, DateTime.utc_now()}

  def from_unix!(time, atom) do
    DateTime.from_unix!(time, atom)
  end
end
