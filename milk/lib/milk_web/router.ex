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
    # post "/signup", UserController, :create
    # post "/signin", UserController, :login
    get "/user/get_all_username", UserController, :all_username
    post "/profile", ProfileController, :get_profile
    post "/profile/update", ProfileController, :update
    post "/profile/update_icon", ProfileController, :update_icon
    get "/profile/get_icon", ProfileController, :get_icon
    get "/game/list", GameController, :list
    post "/game/add", GameController, :create
    post "/achievement/list", AchievementController, :show
    post "/achievement/add", AchievementController, :add
  end

  scope "/api", MilkWeb do
    pipe_through :api

    resources "/user", UserController, except: [:new, :edit, :index, :show, :create]
  
    post "/user/get_all", UserController, :index
    post "/user/get", UserController, :show
    post "/user/in_touch", UserController, :get_users_in_touch
    post "/user/signup", UserController, :create
    post "/user/login", UserController, :login
    post "/user/login_forced", UserController, :login_forced
    post "/user/logout", UserController, :logout

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]

    post "/chat_room/get_all", ChatRoomController, :index
    post "/chat_room/get", ChatRoomController, :show
    post "/chat_room/get_mine", ChatRoomController, :my_rooms

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
    post "/tournament/start", TournamentController, :start
    post "/tournament/deleteloser", TournamentController, :delete_loser
    post "/tournament/get", TournamentController, :show
    post "/tournament/get_all", TournamentController, :index
    post "/tournament/get_by_master_id", TournamentController, :get_tournament_by_master_id
    post "/tournament/get_game", TournamentController, :get_game
    post "/tournament/delete", TournamentController, :delete
    post "/tournament/get_participating_tournaments", TournamentController, :participating_tournaments
    post "/tournament/get_tabs", TournamentController, :tournament_tabs
    post "/tournament/get_thumbnail", TournamentController, :get_thumbnail_image

    resources "/entrant", EntrantController, except: [:new, :edit, :index, :show, :delete]
    post "/entrant/get", EntrantController, :show
    post "/entrant/get_all", EntrantController, :index
    post "/entrant/delete", EntrantController, :delete

    resources "/assistant", AssistantController, except: [:new, :edit, :index, :show, :delete]
    post "/assistant/get", AssistantController, :show
    post "/assistant/get_all", AssistantController, :index
    post "/assistant/delete", AssistantController, :delete

    resources "/relation", RelationController, except: [:new, :edit, :index, :show, :delete]
    post "/sync", SyncController, :sync
  end

  # Other scopes may use custom stacks.
  # scope "/api", MilkWeb do
  #   pipe_through :api
  # end
end
