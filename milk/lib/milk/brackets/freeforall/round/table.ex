defmodule Milk.Brackets.FreeForAll.Round.Table do
  @moduledoc """
  対戦カード
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.Bracket

  schema "brackets_freeforall_round_table" do
    field :name, :string
    field :round_index, :integer
    field :is_finished, :boolean
    field :current_match_index, :integer, default: 0

    belongs_to :bracket, Bracket

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:name, :round_index, :bracket_id, :is_finished, :current_match_index])
    |> foreign_key_constraint(:bracket_id)
  end
end
