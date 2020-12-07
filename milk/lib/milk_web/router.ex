defmodule MilkWeb.Router do
  use MilkWeb, :router
  # FIXME: ルーティングの整理

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
    post "/profile", ProfileController, :get_profile
    post "/profile/update", ProfileController, :update
    post "/profile/update_icon", ProfileController, :update_icon
    get "/profile/get_icon", ProfileController, :get_icon
    get "/game/list", GameController, :list
    post "/game/add", GameController, :create
    post "/achievement/list", AchievementController, :show
    post "/achievement", AchievementController, :create
    post "/achievement/update", AchievementController, :update
    get "/achievement/index", AchievementController, :index
    delete "/achievement/delete", AchievementController, :delete
    post "/achievement/show_one", AchievementController, :show_one
  end

  scope "/api", MilkWeb do
    pipe_through :api

    resources "/user", UserController, except: [:new, :edit, :index, :show, :create, :update]
    get  "/user/get_all_username", UserController, :all_username
    get  "/user/get", UserController, :show
    get  "/user/in_touch", UserController, :users_in_touch
    post "/user/update", UserController, :update
    post "/user/signup", UserController, :create
    post "/user/login", UserController, :login
    post "/user/login_forced", UserController, :login_forced
    post "/user/logout", UserController, :logout

    resources "/relation", RelationController, except: [:new, :edit, :index, :show, :delete]
    get  "/relation/following_list", RelationController, :following_list
    get  "/relation/following_id_list", RelationController, :following_id_list
    get  "/relation/followers_list", RelationController, :followers_list
    get  "/relation/followers_id_list", RelationController, :followers_id_list
    post "/relation/follow", RelationController, :create
    post "/relation/unfollow", RelationController, :delete

    resources "/chat", ChatsController, except: [:new, :edit, :index, :show, :delete]
    post "/chat/create_dialogue", ChatsController, :create_dialogue

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]
    get  "/chat_room/private_rooms", ChatRoomController, :private_rooms

## ↑ここまで整理した

    get  "/chat_room/private_room", ChatRoomController, :private_room

    resources "/chat_room_log", ChatRoomLogController, except: [:new, :edit, :index, :show]
    resources "/chat_log", ChatsLogController, except: [:new, :edit, :index, :show]
    resources "/chat_member_log", ChatMemberLogController, except: [:new, :edit, :index, :show]
    resources "/assistant_log", AssistantLogController, except: [:new, :edit, :index, :show]

    resources "/chat_member", ChatMemberController, except: [:new, :edit, :index, :show, :delete]
    post "/chat_member/get", ChatMemberController, :show
    post "/chat_member/get_all", ChatMemberController, :index
    post "/chat_member/delete", ChatMemberController, :delete

    resources "/tournament", TournamentController, except: [:new, :edit, :index, :show, :delete]
    post "/tournament/get_users_for_add_assistant", TournamentController, :get_users_for_add_assistant
    post "/tournament/start", TournamentController, :start
    post "/tournament/deleteloser", TournamentController, :delete_loser
    post "/tournament/get", TournamentController, :show
    post "/tournament/get_all", TournamentController, :index
    post "/tournament/get_by_master_id", TournamentController, :get_tournaments_by_master_id
    post "/tournament/get_planned", TournamentController, :get_going_tournaments_by_master_id
    post "/tournament/get_game", TournamentController, :get_game
    post "/tournament/get_opponent", TournamentController, :get_opponent
    post "/tournament/delete", TournamentController, :delete
    post "/tournament/get_participating_tournaments", TournamentController, :participating_tournaments
    post "/tournament/get_tabs", TournamentController, :tournament_topics
    post "/tournament/get_thumbnail", TournamentController, :get_thumbnail_image
    post "/tournament/get_match_list", TournamentController, :get_match_list
    post "/tournament/home", TournamentController, :home
    post "/tournament/image", TournamentController, :image
    post "/tournament/publish_url", TournamentController, :publish_url
    post "/tournament/members", TournamentController, :get_match_members
    post "/tournament_log/add", TournamentLogController, :create
    post "/tournament/start_match", TournamentController, :start_match
    post "/tournament/claim_win", TournamentController, :claim_win
    post "/tournament/claim_lose", TournamentController, :claim_lose
    post "/tournament/find_match", TournamentController, :find_match
    post "/tournament/masters", TournamentController, :get_game_masters
    post "/tournament/finish", TournamentController, :finish

    # DEBUG
    post "/tournament/debug_match_list", TournamentController, :debug_match_list

    resources "/entrant", EntrantController, except: [:new, :edit, :delete]
    delete "/entrant/delete", EntrantController, :delete
    get  "/entrant/rank/:tournament_id/:user_id", EntrantController, :show_rank
    resources "/entrant_log", EntrantLogController

    resources "/assistant", AssistantController, except: [:new, :edit, :index, :show, :delete]
    post "/assistant/get", AssistantController, :show
    post "/assistant/get_all", AssistantController, :index
    post "/assistant/delete", AssistantController, :delete

    post "/live", LiveController, :create
    post "/live/home", LiveController, :home

    post "/sync", SyncController, :sync

    post "/send_email", ConfNumController, :send_email
    post "/conf_email", ConfNumController, :conf_email

    post "/notif/get_list", NotifController, :get_list
    post "/notif/create", NotifController, :create
    post "/notif_log/create", NotifLogController, :create
    delete "/notif/:id", NotifController, :delete
  end
end
