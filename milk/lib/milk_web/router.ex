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
    # plug Milk.UserManager.GuardianPipline
  end

  scope "/", MilkWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", MilkWeb do
    post "/signup", UserController, :create
    get "/user/get_all_username", UserController, :all_username
    post "/profile", ProfileController, :get_profile
    post "/profile/update", ProfileController, :update
    post "/profile/update_icon", ProfileController, :update_icon
    get "/profile/get_icon", ProfileController, :get_icon
    get "/game/list", GameController, :list
    post "/game/add", GameController, :add
    post "/achievement/list", AchievementController, :show
    post "/achievement/add", AchievementController, :add
  end

  scope "/api", MilkWeb do
    pipe_through :api

    resources "/user", UserController, except: [:new, :edit, :index, :show, :create]
  
    post "/user/get_all", UserController, :index
    post "/user/get", UserController, :show
    post "/user/signup", UserController, :create
    post "/user/login", UserController, :login
    post "/user/login_forced", UserController, :login_forced
    post "/user/logout", UserController, :logout

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]

    post "/chat_room/get_all", ChatRoomController, :index
    post "/chat_room/get", ChatRoomController, :show

    resources "/chat_member", ChatMemberController, except: [:new, :edit, :index, :show, :delete]
    post "/chat_member/get", ChatMemberController, :show
    post "/chat_member/get_all", ChatMemberController, :index
    post "/chat_member/delete", ChatMemberController, :delete

    resources "/chat", ChatsController, except: [:new, :edit, :index, :show, :delete]
    # post "/chat/get", ChatMemberController, :show
    post "/chat/get", ChatsController, :index
    post "/chat/latest", ChatsController, :get_latest
    post "/chat/sync", ChatsController, :sync
    post "/chat/delete", ChatsController, :delete
    post "/chat/create_dialogue", ChatsController, :create_dialogue

    resources "/tournament", TournamentController, except: [:new, :edit, :index, :show, :delete]
    post "/tournament/get", TournamentController, :show
    post "/tournament/get_all", TournamentController, :index
    post "/tournament/get_game", TournamentController, :get_game
    post "/tournament/delete", TournamentController, :delete

    resources "/entrant", EntrantController, except: [:new, :edit, :index, :show, :delete]
    post "/entrant/get", EntrantController, :show
    post "/entrant/get_all", EntrantController, :index
    post "/entrant/delete", EntrantController, :delete

    resources "/assistant", AssistantController, except: [:new, :edit, :index, :show, :delete]
    post "/assistant/get", AssistantController, :show
    post "/assistant/get_all", AssistantController, :index
    post "/assistant/delete", AssistantController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", MilkWeb do
  #   pipe_through :api
  # end
end
