defmodule Milk.Brackets.FreeForAll.Round.MatchInformation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.FreeForAll.Round.Information

  schema "brackets_freeforall_round_matchinformation" do
    field :score, :integer

    belongs_to :round, Information

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end
defmodule Milk.Brackets.FreeForAll.Round.MatchInformation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Brackets.FreeForAll.Round.Information

  schema "brackets_freeforall_round_matchinformation" do
    field :score, :integer

    belongs_to :round, Information

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end
