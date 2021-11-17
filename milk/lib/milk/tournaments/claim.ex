defmodule Milk.Tournaments.Claim do
  @moduledoc """
  Claimするときにレスポンスとして使用する構造体
  """
  alias Milk.Tournaments.InteractionMessage

  defstruct [
    :interaction_messages,
    :validated,
    :completed,
    :is_finished,
    :rule
  ]

  @type t :: %__MODULE__{
    interaction_messages: [InteractionMessage.t()],
    validated:            boolean(),
    completed:            boolean(),
    is_finished:          boolean(),
    rule:                 String.t()
  }
end
