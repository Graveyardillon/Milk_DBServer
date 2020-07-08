defmodule MilkWeb.UserController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Accounts.Auth
  alias Milk.Accounts.User

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json",
      user: Map.put(user, :auth, %Auth{email: user_params["email"]}))
    else
      _ ->
        render(conn, "show.json",user: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    else
      _ -> render(conn, "show.json", user: nil)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def login(conn, %{"user" => user_params}) do
    user = Accounts.login(user_params)
    render(conn, "show.json", user: user)
  end

  def login_forced(conn, %{"user" => user_params}) do
    user = Accounts.login_forced(user_params)
    render(conn, "show.json", user: user)
  end

  def logout(conn, %{"id" => id}) do
    result = Accounts.logout id
    json(conn, %{result: result})
  end
end
