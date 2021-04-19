defmodule Milk.Enum do
  @doc """
  Creep along match_list
  """
  def creep(match_list, f) do
    Enum.each(match_list, fn x ->
      case x do
        x when is_list(x) -> creep(x, f)
        x -> f.(x)
      end
    end)
  end
end
