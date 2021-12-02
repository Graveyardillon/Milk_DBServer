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
    :opponent_user_id,
    :rule,
    :user_id
  ]

  @type t :: %__MODULE__{
    interaction_messages: [InteractionMessage.t()],
    validated:            boolean(),
    completed:            boolean(),
    is_finished:          boolean(),
    opponent_user_id:     integer() | nil,
    rule:                 String.t(),
    user_id:              integer() | nil
  }
end
