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
      {:ok, token, _} = Guardian.encode_and_sign(user)
      %{data: render_one(user, UserView, "user.json"), result: true, token: token}
    else
      %{data: nil, result: false}
    end
  end

  def render("login_forced.json", %{user: user}) do
    if user do
      {:ok, token, _} = Guardian.signin_forced(user)
      %{data: render_one(user, UserView, "user.json"), result: true, token: token}
    else
      %{data: nil, result: false}
    end
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      name: user.name,
      icon_path: user.icon_path,
      point: user.point,
      notification_number: user.notification_number,
      language: user.language,
      email: user.auth.email
    }
  end
end
