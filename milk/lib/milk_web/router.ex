defmodule MilkWeb.Router do
  use MilkWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Milk.UserManager.GuardianPipline
  end

  scope "/", MilkWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", MilkWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit, :index, :show]

    post "/users/get_all", UserController, :index
    post "/users/get", UserController, :show
    post "/users/login", UserController, :login
    post "/users/login_forced", UserController, :login_forced
    post "users/logout/", UserController, :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", MilkWeb do
  #   pipe_through :api
  # end
end
