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

    get "/game/list", GameController, :list
    post "/game/add", GameController, :add
    post "/profile/add", ProfileController, :add
    post "/profile/fav_games", ProfileController, :fav_games
    post "/profile/delete_game", ProfileController, :delete_game
    post "/profile/delete_achievement". ProfileController, :delete_achievement
  end

  scope "/api", MilkWeb do
    pipe_through :api

    resources "/user", UserController, except: [:new, :edit, :index, :show]
  
    post "/user/get_all", UserController, :index
    post "/user/get", UserController, :show
    post "/user/login", UserController, :login
    post "/user/login_forced", UserController, :login_forced
    post "/user/logout/", UserController, :logout

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]

    post "/chat_room/get_all", ChatRoomController, :index
    post "/chat_room/get", ChatRoomController, :show

    resources "/chat_member", ChatMemberController, except: [:new, :edit, :index, :show, :delete]
    post "/chat_member/get", ChatMemberController, :show
    post "/chat_member/get_all", ChatMemberController, :index
    post "chat_member/delete", ChatMemberController, :delete

    resources "/chat", ChatsController, except: [:new, :edit, :index, :show, :delete]
    # post "/chat/get", ChatMemberController, :show
    post "/chat/get", ChatsController, :index
    post "chat/latest", ChatsController, :get_latest
    post "chat/sync", ChatsController, :sync
    post "chat/delete", ChatsController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", MilkWeb do
  #   pipe_through :api
  # end
end
