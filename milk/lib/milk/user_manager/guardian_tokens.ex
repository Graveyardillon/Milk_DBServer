defmodule Milk.UserManager.GuardianTokens do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.Auth

  @primary_key false
  schema "guardian_tokens" do
    field(:jti, :string, primary_key: true)
    field(:aud, :string, primary_key: true)
    field(:typ, :string)
    field(:iss, :string)
    field(:sub, :string)
    field(:exp, :integer)
    field(:jwt, :string)
    field(:claims, :map)

  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:jti, :aud, :typ, :iss, :sub, :exp, :jwt, :claims])
    # |> validate_required([:jti, :aud, :typ, :iss, :sub, :exp, :jwt, :claims])
    |> validate_required([:jti, :aud])
    |> unique_constraint([:jti, :aud])
  end
end