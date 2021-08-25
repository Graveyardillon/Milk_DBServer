defmodule Milk.Accounts.ExternalService do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "external_services" do
    field :content, :string, null: false
    field :name, :string, null: false

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(external_service, attrs) do
    external_service
    |> cast(attrs, [:content, :name, :user_id])
    |> validate_required([:content, :name, :user_id])
  end
end
