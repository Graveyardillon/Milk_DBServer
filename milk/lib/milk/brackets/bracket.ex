defmodule Milk.Brackets.Bracket do
  @moduledoc """
  トーナメント表のみを利用するときに使用するスキーマ構造体
  """
  use Milk.Schema

  alias Milk.Accounts.User

  schema "brackets" do
    field :name, :string
    field :url, :string
    field :enabled_bronze_medal_match, :boolean, default: false
    field :is_started, :boolean, default: false

    field :rule, :string
    field :match_list_str, :string
    field :match_list_with_fight_result_str, :string
    field :last_match_list_str, :string
    field :last_match_list_with_fight_result_str, :string

    belongs_to :owner, User

    timestamps()
  end

  def changeset(bracket, attrs) do
    bracket
    |> cast(attrs,
      [
        :name,
        :url,
        :enabled_bronze_medal_match,
        :is_started,
        :owner_id,
        :rule,
        :match_list_str,
        :match_list_with_fight_result_str,
        :last_match_list_str,
        :last_match_list_with_fight_result_str
      ]
    )
    |> unique_constraint(:url)
  end
end
