defmodule Milk.Tournaments.Rules do
  @moduledoc """
  Rules for tournament.
  """
  @type opts :: [is_team: boolean()]

  @spec db_index() :: integer()
  def db_index(), do: Application.get_env(:milk, :dfa_db_index)

  @spec adapt_keyname(integer()) :: String.t()
  def adapt_keyname(user_id), do: "user:#{user_id}"
end
