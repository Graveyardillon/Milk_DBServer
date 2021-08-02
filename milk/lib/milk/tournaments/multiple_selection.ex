defmodule Milk.Tournaments.MultipleSelection do
  use Milk.Schema

  import Ecto.Changeset
  import Common.Sperm

  alias Milk.Tournaments.Tournament
  alias Milk.Contants.Tournament.MultipleSelection

  schema "multiple_selections" do
    field :state, :string, default: "not_selected"
    field :name, :string

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(multiple_selection, attrs) do
    multiple_selection
    |> cast(attrs, [:state, :name, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end

  @doc """
  All states of the selection.
  """
  def state(key \\ "not_selected") do
    %{
      not_selected: "not_selected
    "}
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
