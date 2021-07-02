defmodule Milk.Tournaments.Team do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "teams" do
    field :name, :string
    field :size, :integer

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :size])
  end
end
