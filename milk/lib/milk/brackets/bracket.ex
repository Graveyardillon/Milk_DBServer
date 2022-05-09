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

    belongs_to :owner, User

    timestamps()
  end

  def changeset(bracket, attrs) do
    bracket
    |> cast(attrs, [:name, :url, :enabled_bronze_medal_match, :owner_id])
    |> unique_constraint(:url)
  end
end
