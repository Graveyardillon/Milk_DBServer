defmodule Milk.Tournaments.Map do
  use Milk.Schema

  import Ecto.Changeset
  import Common.Sperm

  alias Milk.Tournaments.Tournament

  schema "maps" do
    field :name, :string
    field :icon_path, :string

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(map, attrs) do
    map
    |> cast(attrs, [:name, :tournament_id, :icon_path])
    |> foreign_key_constraint(:tournament_id)
  end

  @doc """
  All states of the selection.
  """
  def state(key \\ "not_selected") do
    %{
      not_selected: "not_selected",
      selected: "selected",
      banned: "banned"
    }
    |> Map.get(key)
    ~> state
    |> is_nil()
    |> unless do
      state
    else
      raise "Undefined state"
    end
  end
end
