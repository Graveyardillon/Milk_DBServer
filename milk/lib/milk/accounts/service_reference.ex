defmodule Milk.Accounts.ServiceReference do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "service_references" do
    field :riot_id, :string, null: true
    field :twitter_id, :string, null: true

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(service_reference, attrs) do
    service_reference
    |> cast(attrs, [:riot_id, :twitter_id, :user_id])
  end
end
