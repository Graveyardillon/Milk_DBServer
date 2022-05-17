defmodule Milk.Brackets.FreeForAll.Information do
  @moduledoc """
  情報
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.Bracket

  schema "brackets_freeforall_information" do
    field :round_number, :integer
    field :match_number, :integer
    field :round_capacity, :integer
    field :enable_point_multiplier, :boolean, default: false

    belongs_to :bracket, Bracket

    timestamps()
  end

  @doc false
  def changeset(information, attrs) do
    information
    |> cast(attrs, [:round_number, :match_number, :round_capacity, :enable_point_multiplier, :bracket_id])
    |> foreign_key_constraint(:bracket_id)
  end
end
