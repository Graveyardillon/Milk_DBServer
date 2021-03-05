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
    pipe_through :api

    resources "/user", UserController, except: [:new, :edit, :index, :show, :create, :update]
    post  "/user/check_username_duplication", UserController, :check_username_duplication
    get  "/user/get", UserController, :show
    get  "/user/in_touch", UserController, :users_in_touch
    post "/user/update", UserController, :update
    get  "/user/get_all", UserController, :index
    post "/user/get", UserController, :show
    post "/user/in_touch", UserController, :get_users_in_touch
    post "/user/signup", UserController, :create
    post "/user/signin", UserController, :login
    post "/user/login_forced", UserController, :login_forced
    post "/user/logout", UserController, :logout
    post "/user/change_password", UserController, :change_password

    post "/user_report", ReportController, :create

    post "/profile", ProfileController, :get_profile
    post "/profile/update", ProfileController, :update
    post "/profile/update_icon", ProfileController, :update_icon
    get  "/profile/get_icon", ProfileController, :get_icon
    get "/profile/records", ProfileController, :records
    
    get  "/game/list", GameController, :list
    post "/game/add", GameController, :create

    resources "/relation", RelationController, except: [:new, :edit, :index, :show, :delete]
    get  "/relation/following_list", RelationController, :following_list
    get  "/relation/following_id_list", RelationController, :following_id_list
    get  "/relation/followers_list", RelationController, :followers_list
    get  "/relation/followers_id_list", RelationController, :followers_id_list
    post "/relation/follow", RelationController, :create
    post "/relation/unfollow", RelationController, :delete

    resources "/chat", ChatsController, except: [:new, :edit, :index, :delete]
    delete "/chat", ChatsController, :delete
    post "/chat/create_dialogue", ChatsController, :create_dialogue
    post "/chat/upload/image", ChatsController, :upload_image
    get  "/chat/load/image", ChatsController, :load_image

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]
    get  "/chat_room", ChatRoomController, :show
    get  "/chat_room/private_rooms", ChatRoomController, :private_rooms
    # FIXME: 副作用があるのでpostにしたほうがいい
    get  "/chat_room/private_room", ChatRoomController, :private_room

    resources "/chat_room_log", ChatRoomLogController, except: [:new, :edit]
    resources "/chat_log", ChatsLogController, except: [:new, :edit]
    resources "/chat_member_log", ChatMemberLogController, except: [:new, :edit]
    resources "/assistant_log", AssistantLogController, except: [:new, :edit]
    resources "/entrant_log", EntrantLogController

    resources "/tournament", TournamentController, except: [:new, :edit, :index, :show, :delete]
    get  "/tournament/users_for_add_assistant", TournamentController, :get_users_for_add_assistant
    get  "/tournament/get", TournamentController, :show
    get  "/tournament/get_by_master_id", TournamentController, :get_tournaments_by_master_id
    get  "/tournament/get_planned", TournamentController, :get_ongoing_tournaments_by_master_id
    get  "/tournament/get_game", TournamentController, :get_game
    get  "/tournament/by_url", TournamentController, :get_tournament_by_url
    get  "/tournament/get_opponent", TournamentController, :get_opponent
    get  "/tournament/get_participating_tournaments", TournamentController, :participating_tournaments
    get  "/tournament/participating", TournamentController, :participating_tournaments
    get  "/tournament/get_tabs", TournamentController, :tournament_topics
    get  "/tournament/get_thumbnail", TournamentController, :get_thumbnail_image
    get  "/tournament/get_match_list", TournamentController, :get_match_list
    get  "/tournament/home", TournamentController, :home
    get  "/tournament/masters", TournamentController, :get_game_masters
    get  "/tournament/members", TournamentController, :get_match_members
    get  "/tournament/find_match", TournamentController, :find_match
    get  "/tournament/get_all", TournamentController, :index
    get  "/tournament/check_pending", TournamentController, :check_pending
    get  "/tournament/brackets", TournamentController, :brackets_with_fight_result
    get  "/tournament/is_user_win", TournamentController, :is_user_win
    get  "/tournament/relevant", TournamentController, :relevant
    get  "/tournament/has_lost", TournamentController, :has_lost?
    get  "/tournament/state", TournamentController, :state
    post "/tournament/start", TournamentController, :start
    post "/tournament/deleteloser", TournamentController, :delete_loser
    # FIXME: このgetはpostメソッドなので消したほうがいい
    post "/tournament/get", TournamentController, :show
    post "/tournament/get_by_master_id", TournamentController, :get_tournaments_by_master_id
    post "/tournament/get_planned", TournamentController, :get_ongoing_tournaments_by_master_id
    post "/tournament/get_game", TournamentController, :get_game
    post "/tournament/get_opponent", TournamentController, :get_opponent
    post "/tournament/delete", TournamentController, :delete
    post "/tournament/update_tabs", TournamentController, :tournament_update_topics
    post "/tournament/publish_url", TournamentController, :publish_url
    post "/tournament/start_match", TournamentController, :start_match
    post "/tournament/claim_win", TournamentController, :claim_win
    post "/tournament/claim_lose", TournamentController, :claim_lose
    post "/tournament/finish", TournamentController, :finish
    get  "/tournament_log/index", TournamentLogController, :index
    post "/tournament_log/add", TournamentLogController, :create

    resources "/entrant", EntrantController, except: [:new, :edit, :delete]
    # FIXME: GETのパラメータの渡し方を統一したい
    get  "/entrant/rank/:tournament_id/:user_id", EntrantController, :show_rank
    delete "/entrant/delete", EntrantController, :delete
    resources "/entrant_log", EntrantLogController
    post "/entrant/rank/promote", EntrantController, :promote

    resources "/assistant", AssistantController, except: [:new, :edit, :index, :show, :delete, :update]
    post "/assistant/delete", AssistantController, :delete

    get  "/live/home", LiveController, :home
    post "/live", LiveController, :create

    post "/sync", SyncController, :sync

    post "/conf/send_email", ConfNumController, :send_email
    post "/conf/conf_email", ConfNumController, :conf_email

    get  "/notification/list", NotifController, :get_list
    post "/notification/create", NotifController, :create
    post "/notification_log/create", NotifLogController, :create
    delete "/notification/delete", NotifController, :delete
  end

  scope "/debug", MilkWeb do
    # FIXME: 見た感じ使われてなさそうだったけど、一応残しておいた
    get  "/tournament/image", TournamentController, :image
    post "/tournament/get_all", TournamentController, :index
    get  "/tournament/debug_match_list", TournamentController, :debug_match_list
    post "/assistant/get", AssistantController, :show
    post "/assistant/get_all", AssistantController, :index

    # ETSのデバッグ用
    post "/observe", DebugController, :observe
  end
end
