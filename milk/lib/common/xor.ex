defmodule Common.Xor do
  use Bitwise

  @spec boolean() <|> boolean() :: Macro.t()
  defmacro left <|> right do
    quote do
      (not unquote(left) and unquote(right)) or (unquote(left) and not unquote(right))
    end
  end
end
