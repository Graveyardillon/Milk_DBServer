defmodule MilkWeb.UserController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Accounts.Auth
  alias Milk.Accounts.User
  alias Milk.Chat
  alias Milk.UserManager.Guardian

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn,"index.json", users: users)
  end

  def get_users_in_touch(conn, %{"user_id" => id}) do
    users = Accounts.get_users_in_touch(id)

    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, %User{} = user} ->
        render(conn, "login.json", %{user: user})

      {:error, error} ->
        case error do
          [email: {"has already been taken", _ }] -> render(conn, "error.json", error_code: 101)
          [password: {"should be at least %{count} character(s)", _ }] -> render(conn, "error.json", error_code: 102)
          [password: {"has invalid format", _ }] -> render(conn, "error.json", error_code: 103)
          _ -> render(conn, "error.json", error: error)
        end

      _ ->
        render(conn, "show.json",user: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case  Accounts.get_user(id) |> Accounts.update_user(user_params) do
      {:ok, %User{} = user} ->
        render(conn, "show.json", user: user)
      {:error, error} ->
        render(conn, "error.json", error: error)

      _ -> render(conn, "show.json", user: nil)
    end
  end

  def delete(conn, %{"id" => id, "password" => password, "email" => email, "token" => _token}) do
    with {:ok, %User{}} <- Accounts.delete_user(id, password, email) do
      # Guardian.revoke(token)
      send_resp(conn, :no_content, "")
    end
  end

  def login(conn, %{"user" => user_params}) do
    user = Accounts.login(user_params)
    case user do
      nil -> render(conn, "error.json", error_code: 104)
      _ -> render(conn, "login.json", %{user: user})
     end
  end

  def login_forced(conn, %{"user" => user_params}) do
    user = Accounts.login_forced(user_params)
    render(conn, "login_forced.json", %{user: user})
  end

  def logout(conn, %{"id" => id, "token" => token}) do
    result = Accounts.logout id
    
      Guardian.revoke(token)
      json(conn, %{result: result})
  end
end
