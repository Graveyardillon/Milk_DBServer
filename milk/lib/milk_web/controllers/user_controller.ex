defmodule MilkWeb.UserController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Tournaments
  }

  alias Milk.Accounts.User
  alias Milk.UserManager.Guardian

  @doc """
  Get user number.
  """
  def number(conn, _params) do
    num = Accounts.get_user_number()
    json(conn, %{result: true, num: num})
  end

  @doc """
  Checks if username has been taken.
  """
  def check_username_duplication(conn, %{"name" => name}) do
    case Accounts.check_duplication?(name) do
      true ->
        json(conn, %{is_unique: false})

      false ->
        json(conn, %{is_unique: true})
    end
  end

  @doc """
  Creates a user.
  """
  def create(conn, %{"user" => user_params}) do
    user_params
    |> Accounts.create_user()
    |> case do
      {:ok, %User{} = user} -> generate_token(user)
      x -> x
    end
    |> case do
      {:ok, token, %User{} = user} ->
        {:ok, token, user}

      {:error, error} ->
        {:error, error}
    end
    |> case do
      {:ok, token, %User{} = user} ->
        render(conn, "login.json", %{user: user, token: token})

      {:error, error} ->
        case error do
          [email: {"has already been taken", _}] ->
            render(conn, "error.json", error_code: 101)

          [password: {"should be at least %{count} character(s)", _}] ->
            render(conn, "error.json", error_code: 102)

          [password: {"has invalid format", _}] ->
            render(conn, "error.json", error_code: 103)

          _ ->
            render(conn, "error.json", error: error)
        end
    end
  end

  @doc """
  Login process.
  """
  def login(conn, %{"user" => user_params}) do
    user_params
    |> Accounts.login()
    |> case do
      {:ok, %User{} = user} -> generate_token(user)
      x -> x
    end
    |> case do
      {:ok, token, %User{} = user} -> render(conn, "login.json", %{user: user, token: token})
      {:error, nil} -> render(conn, "error.json", error_code: 104)
      {:error, error} -> render(conn, "error.json", error: error)
      _ -> render(conn, "error.json", error_code: 104)
    end
  end

  @doc """
  Forced login process.
  """
  def login_forced(conn, %{"user" => user_params}) do
    user = Accounts.login_forced(user_params)
    render(conn, "login_forced.json", %{user: user})
  end

  defp generate_token(user) do
    user
    |> is_nil()
    |> unless do
      user
      |> Guardian.encode_and_sign()
      |> case do
        {:ok, token, _full_claims} -> {:ok, token, user}
        {:error, error} -> {:error, error}
        _ -> {:error, nil}
      end
    else
      {:error, "user is nil"}
    end
  end

  @doc """
  Logout process.
  """
  def logout(conn, %{"id" => id, "token" => token}) do
    token
    |> Guardian.decode_and_verify()
    |> case do
      {:ok, _claims} ->
        result = Accounts.logout(id)
        json(conn, %{result: result})

      _ ->
        json(conn, %{result: false})
    end
  end

  @doc """
  Shows user details.
  """
  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    render(conn, "show.json", user: user)
  end

  @doc """
  Gets users in touch.
  """
  def users_in_touch(conn, %{"user_id" => id}) do
    users = Accounts.get_users_in_touch(id)

    render(conn, "index.json", users: users)
  end

  @doc """
  Search.
  """
  def search(conn, %{"text" => text, "team_filter" => _, "tournament_id" => tournament_id}) do
    tournament_id
    |> Tournaments.get_teams_by_tournament_id()
    |> Enum.map(fn team ->
      team
      |> Map.get(:id)
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.map(fn member ->
        member
        |> Map.get(:user)
      end)
      |> List.flatten()
      |> Enum.uniq()
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn user ->
      user.id
    end)
    ~> team_id_list

    text
    |> Accounts.search()
    |> Enum.filter(fn user ->
      !(user.id in team_id_list)
    end)
    ~> users

    render(conn, "index.json", users: users)
  end

  def search(conn, %{"text" => text}) do
    users = Accounts.search(text)

    render(conn, "index.json", users: users)
  end

  @doc """
  Updates user.
  """
  def update(conn, %{"id" => id, "user" => user_params, "token" => token}) do
    case Guardian.decode_and_verify(token) do
      {:ok, _} ->
        case Accounts.get_user(id) |> Accounts.update_user(user_params) do
          {:ok, %User{} = user} ->
            render(conn, "show.json", user: user)

          {:error, error} ->
            render(conn, "error.json", error: error)

          _ ->
            render(conn, "show.json", user: nil)
        end

      _ ->
        json(conn, %{msg: "Invalid token"})
    end
  end

  def update(conn, %{"id" => _id, "user" => _user}) do
    json(conn, %{message: "Missing token"})
  end

  @doc """
  Deletes a user.
  """
  def delete(conn, %{"id" => id, "password" => password, "email" => email, "token" => token}) do
    id = Tools.to_integer_as_needed(id)

    Accounts.delete_user(id, password, email, token)
    |> case do
      {:ok, _} ->
        Guardian.revoke(token)
        # send_resp(conn, :no_content, "")
        json(conn, %{result: true})

      _ ->
        json(conn, %{result: false})
    end
  end

  @doc """
  Change password with email and given token.
  """
  def change_password(conn, %{"email" => email, "token" => token, "new_password" => new_password}) do
    gotten_token =
      Milk.Email.Auth.get_token()
      |> Map.get(email)

    if gotten_token == token do
      Accounts.change_password_by_email(email, new_password)
    else
      {:error, "token does not match"}
    end
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      _ -> json(conn, %{result: false})
    end
  end
end
