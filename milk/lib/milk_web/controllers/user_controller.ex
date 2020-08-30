defmodule MilkWeb.UserController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Accounts.Auth
  alias Milk.Accounts.User
  alias Milk.UserManager.Guardian

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn,"index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, %User{} = user} ->
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("login.json",
      %{user: Map.put(user, :auth, %Auth{email: user_params["email"]})})

      {:error, error} ->
        render(conn, "error.json", error: error)

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

  def delete(conn, %{"id" => id, "password" => password, "email" => email, "token" => token}) do
    user = Accounts.check_user(id, password, email)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      # Guardian.revoke(token)
      send_resp(conn, :no_content, "")
    end
  end

  def login(conn, %{"user" => user_params}) do
    user = Accounts.login(user_params)
    render(conn, "login.json", %{user: user})
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
