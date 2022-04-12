defmodule Milk.Tournaments.InteractionMessage do
  @moduledoc """
  WebServer側ではstateとuser_idの紐付いたリストを使用するので、そのための構造体
  """

  defstruct [
    :state,
    :user_id
  ]

  @type t :: %__MODULE__{
    state: String.t(),
    user_id: integer()
  }
end
