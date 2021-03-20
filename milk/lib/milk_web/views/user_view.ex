defmodule MilkWeb.UserView do
  use MilkWeb, :view
  alias MilkWeb.UserView
  alias Milk.UserManager.Guardian

  def render("index.json", %{users: users}) do
    if users != [] do
      %{data: render_many(users, UserView, "user.json"), result: true}
    else
      %{data: nil, result: false}
    end
  end

  def render("show.json", %{user: user}) do
    if user do
      %{data: render_one(user, UserView, "user.json"), result: true}
    else
      %{data: nil, result: false}
    end
  end

  def render("login.json", %{user: user}) do
    if user do
      case Guardian.encode_and_sign(user) do
        {:ok, token, _} ->
          %{data: render_one(user, UserView, "user.json"), result: true, token: token}
        {:error, error} ->
          %{result: false, error: create_message(error), data: nil}
        _ ->
          %{result: false, data: nil}
      end
    else
      %{data: nil, result: false}
    end
  end

  def render("login_forced.json", %{user: user}) do
    if user do
      case Guardian.signin_forced(user) do
        {:ok, token, _} ->
          %{data: render_one(user, UserView, "user.json"), result: true, token: token}
        {:error, _error} ->
          %{result: false, error: "can't get token", data: nil}
        _ ->
          %{result: false, data: nil}
      end
    else
      %{data: nil, result: false}
    end
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: create_message(error), data: nil}
  end

  def render("error.json", %{error_code: num}) do
    %{result: false, error_code: num, data: nil}
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      icon_path: user.icon_path,
      point: user.point,
      notification_number: user.notification_number,
      language: user.language,
      email: user.auth.email,
      bio: user.bio
    }
  end
end
