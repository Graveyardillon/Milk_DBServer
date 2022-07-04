defmodule Milk.Brackets.FreeForAll.Status do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.Bracket

  schema "brackets_freeforall_status" do
    field :current_round_index, :integer, default: 0

    belongs_to :bracket, Bracket

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:current_round_index, :bracket_id])
    |> foreign_key_constraint(:bracket_id)
  end
end
