defmodule Common.Tools do
  def to_integer_as_needed(data) do
    if is_binary(data) do
      String.to_integer(data)
    else
      data
    end
  end
end