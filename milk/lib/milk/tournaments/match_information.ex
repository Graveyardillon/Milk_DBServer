defmodule Milk.Tournaments.MatchInformation do
  @moduledoc """
  大会進行で使用する、get_match_information関数のデータをrenderするときに使用する構造体
  """

  alias Milk.Accounts.User
  alias Milk.Tournaments.{
    Map,
    Team,
    TournamentCustomDetail
  }

  defstruct [
    :opponent,
    :rank,
    :is_team,
    :is_leader,
    :is_attacker_side,
    :score,
    :state,
    :map,
    :rule,
    :is_coin_head,
    :custom_detail
  ]

  @type t :: %__MODULE__{
    opponent: User.t() | Team.t() | nil,
    rank: integer() | nil,
    is_team: boolean(),
    is_leader: boolean() | nil,
    is_attacker_side: boolean() | nil,
    score: integer() | nil,
    state: String.t(),
    map: Map.t() | nil,
    rule: String.t(),
    is_coin_head: boolean() | nil,
    custom_detail: TournamentCustomDetail.t() | nil
  }
end
