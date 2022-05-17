defmodule Milk.Brackets.FreeForAll.Round.Information do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.FreeForAll.Round.Table
  alias Milk.Brackets.Participant

  schema "brackets_freeforall_round_information" do
    belongs_to :table, Table
    belongs_to :participant, Participant

    timestamps()
  end

  @doc false
  def changeset(information, attrs) do
    information
    |> cast(attrs, [:table_id, :participant_id])
    |> foreign_key_constraint(:table_id)
    |> foreign_key_constraint(:participant_id)
  end
end
