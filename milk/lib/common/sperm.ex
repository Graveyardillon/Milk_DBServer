defmodule Common.Sperm do
  defmacro left ~> right do
    quote do
      unquote(right) = unquote(left)
    end
  end
end
