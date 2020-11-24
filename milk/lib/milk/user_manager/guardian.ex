defmodule Milk.UserManager.Guardian do
  use Guardian, otp_app: :milk
  import Ecto.Query

  alias Milk.Accounts
  alias Milk.UserManager.GuardianTokens
  alias Milk.Repo
  alias Milk.UserManager.Guardian

  def subject_for_token(user, _claims) do
    id =
      case Map.get(user, :user) do
        nil ->
          user.id
        userinfo ->
          user.user.id
      end
      |> to_string
    {:ok, id}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = Accounts.get_user(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end

  def after_encode_and_sign(_resource, claims, token, _options) do
    # %GuardianTokens{jwt: token, claims: claims}
    # |> GuardianTokens.changeset(claims)
    # |> token_check(token)

    case Repo.transaction(fn ->
      %GuardianTokens{jwt: token, claims: claims}
      |> GuardianTokens.changeset(claims)
      |> Repo.insert
    end) do
    {:ok, {:ok, _}} -> {:ok, token}
    {:ok,{:error, error}} -> {:error, error.errors}
    _ -> {:error, %{errors: [token: "db error"]}}
    end
  end

  # defp token_check(chgst, token) do
  #   if(chgst.valid?) do
  #     with {:ok, _} <- Repo.insert(chgst) do
  #       {:ok, token}
  #     else
  #       error ->
  #         Repo.delete(chgst)
  #         {:error, error}
  #     end
  #   else
  #     {:error, chgst.errors}
  #   end
  # end

  def on_verify(claims, _token, _options) do
    Repo.exists?(from g in GuardianTokens, where: g.jti == ^claims["jti"] and g.aud == ^claims["aud"])
    |> if do
      {:ok, claims}
    else
      {:error, :not_exist}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    {:ok, {old_token, old_claims}, {new_token, new_claims}}
  end

  def on_revoke(claims, _token, _options) do
    Repo.delete_all(from g in GuardianTokens, where: (g.jti == ^claims["jti"] and g.aud == ^claims["aud"]) or g.exp <= ^DateTime.to_unix(DateTime.utc_now))
    {:ok, claims}
  end

  def signin_forced(user) do
    Repo.delete_all(from g in GuardianTokens, where: g.sub == ^to_string(user.id))
    Guardian.encode_and_sign(user)
  end

  def signout(token) do
    {:ok, claims} = Guardian.revoke(token)
    Accounts.logout(claims["sub"])
  end
end