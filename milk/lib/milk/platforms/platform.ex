defmodule Milk.Platforms.Platform do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "platforms" do
    field :name, :string

    has_many :tournament, Tournament
  end

  def changeset(platform, attrs) do
    platform
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
