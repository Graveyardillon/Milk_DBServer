defmodule Milk.Accounts.Auth do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "auth" do
    field :email, :string, null: false
    field :password, :string, null: false
    field :service_name, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(auth, attrs) do
    auth
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8)
    # パスワードは半角英数大文字小文字をそれぞれ一文字以上含む
    |> validate_format(:password, ~r/\A(?=.*?[a-z])(?=.*?[A-Z])(?=.*?\d)[a-zA-Z\d]/)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  @doc false
  def changeset_update(auth, attrs) do
    auth
    |> cast(attrs, [:email, :password])
    |> unique_constraint(:email)
    |> validate_length(:password, min: 8)
    # パスワードは半角英数大文字小文字をそれぞれ一文字以上含む
    |> validate_format(:password, ~r/\A(?=.*?[a-z])(?=.*?[A-Z])(?=.*?\d)[a-zA-Z\d]/)
    |> put_password_hash()
  end

  @doc false
  def changeset_discord(auth, attrs) do
    auth
    |> cast(attrs, [:email, :service_name])
    |> put_change(:service_name, "discord")
    |> validate_required(:email)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password: create_pass(password))
  end

  defp put_password_hash(changeset), do: changeset

  def create_pass(password) do
    Argon2.hash_pwd_salt(password)
  end
end
