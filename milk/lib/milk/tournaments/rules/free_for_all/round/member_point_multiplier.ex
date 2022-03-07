defmodule Milk.Tournaments.Rules.FreeForAll.Round.MemberPointMultiplier do
  @moduledoc """
  キルポイントとかのスコアを実際に記録しておくためのやつ（チームメンバー）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.MemberMatchInformation
  alias Milk.Tournaments.Rules.FreeForAll.PointMultiplierCategory, as: Category

  schema "tournaments_rules_freeforall_round_memberpointmultipliers" do
    field :point, :integer

    belongs_to :member_match_information, MemberMatchInformation
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(multipliers, attrs) do
    multipliers
    |> cast(attrs, [:point, :member_match_information_id, :category_id])
    |> foreign_key_constraint(:member_match_information_id)
    |> foreign_key_constraint(:category_id)
  end
end
