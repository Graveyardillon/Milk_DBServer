defmodule Milk.Lives.Live do
  use Milk.Schema
  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  schema "lives" do
    field :name, :string
    field :number_of_viewers, :integer, default: 0
    field :thumbnail_path, :string
    field :url, :string
    belongs_to :tournament, Tournament
    belongs_to :streamer, User

    timestamps()
  end

  @doc false
  def changeset(live, attrs) do
    live
    |> cast(attrs, [:name, :number_of_viewers, :thumbnail_path])
    |> validate_required([:name])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:streamer_id)
  end
end
