defmodule Common.XorTest do
  @moduledoc """
  test of xor
  """

  use Milk.DataCase

  import Common.Xor

  describe "xor" do
    test "works" do
      refute true <|> true
      assert true <|> false
      assert false <|> true
      refute false <|> false

      with a when a <|> true <- false do
        assert true
      else
        _ -> assert false
      end
    end
  end
end
