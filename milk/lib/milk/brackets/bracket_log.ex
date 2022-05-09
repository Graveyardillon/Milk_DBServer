defmodule Milk.Brackets.BracketLog do
  @moduledoc """
  トーナメント表ログのみを利用するときに使用するスキーマ構造体
  """
  use Milk.Schema

  alias Milk.Accounts.User

  schema "brackets_log" do
    field :name, :string
    field :url, :string
    field :bracket_id, :integer
    field :enabled_bronze_medal_match, :boolean, default: false

    belongs_to :owner, User

    timestamps()
  end

  def changeset(bracket, attrs) do
    bracket
    |> cast(attrs, [:name, :url, :integer, :enabled_bronze_medal_match, :owner_id])
    |> unique_constraint(:url)
  end
end
