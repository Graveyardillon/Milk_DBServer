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

    if Application.get_env(:milk, :environment) == :prod do
      plug Milk.UserManager.GuardianPipeline
      # else
      #   plug Milk.UserManager.GuardianPipeline
    end
  end

  scope "/", MilkWeb do
    pipe_through :browser
    get "/", PageController, :index
  end

  scope "/api", MilkWeb do
    pipe_through :api

    get "/check/connection", CheckController, :connection_check
    post "/check/data_for_web", CheckController, :data_for_web

    resources "/user", UserController, except: [:new, :edit, :index, :show, :create, :update, :delete]

    get "/user/num", UserController, :number
    get "/user/check_username_duplication", UserController, :check_username_duplication
    get "/user/get", UserController, :show
    get "/user/in_touch", UserController, :users_in_touch
    get "/user/search", UserController, :search
    post "/user/update", UserController, :update
    post "/user/get", UserController, :show
    post "/user/in_touch", UserController, :get_users_in_touch
    post "/user/signup", UserController, :create
    post "/user/signin", UserController, :login
    post "/user/signin_with_discord", UserController, :signin_with_discord
    post "/user/signin_with_apple", UserController, :signin_with_apple
    post "/user/login_forced", UserController, :login_forced
    post "/user/signout", UserController, :logout
    post "/user/change_password", UserController, :change_password
    post "/user/change_language", UserController, :change_language
    delete "/user/delete", UserController, :delete
    get "/user/download", UserController, :download

    post "/user_report", ReportController, :create_user_report
    post "/tournament_report", ReportController, :create_tournament_report

    get "/discord/team_name", DiscordController, :team_name
    post "/discord/resend_invitation_links", DiscordController, :resend_invitation_links
    post "/discord/associate", DiscordController, :associate
    post "/discord/create_invitation_link", DiscordController, :create_invitation_link
    delete "/discord/dissociate", DiscordController, :dissociate

    get "/profile", ProfileController, :get_profile
    get "/profile/get", ProfileController, :get_profile
    post "/profile/get", ProfileController, :get_profile
    post "/profile", ProfileController, :get_profile
    post "/profile/update", ProfileController, :update
    post "/profile/update_icon", ProfileController, :update_icon
    get "/profile/get_icon", ProfileController, :get_icon
    get "/profile/records", ProfileController, :records
    get "/profile/external_services", ProfileController, :external_services
    post "/profile/external_service", ExternalServiceController, :create
    delete "/profile/external_service", ExternalServiceController, :delete

    resources "/relation", RelationController, except: [:new, :edit, :index, :show, :delete]
    get "/relation/following_list", RelationController, :following_list
    get "/relation/following_id_list", RelationController, :following_id_list
    get "/relation/followers_list", RelationController, :followers_list
    get "/relation/followers_id_list", RelationController, :followers_id_list
    get "/relation/blocked_users", RelationController, :blocked_users
    post "/relation/follow", RelationController, :create
    post "/relation/unfollow", RelationController, :delete
    post "/relation/block_user", RelationController, :block_user
    post "/relation/unblock_user", RelationController, :unblock_user

    get "/chat/all_chats", ChatsController, :get_all_chats
    resources "/chat", ChatsController, except: [:new, :edit, :index, :delete]
    delete "/chat", ChatsController, :delete
    post "/chat/create_dialogue", ChatsController, :create_dialogue
    post "/chat/upload/image", ChatsController, :upload_image
    get "/chat/load/image", ChatsController, :load_image

    resources "/chat_room", ChatRoomController, except: [:new, :edit, :index, :show]
    get "/chat_room", ChatRoomController, :show
    get "/chat_room/private_rooms", ChatRoomController, :private_rooms
    # FIXME: 副作用があるのでpostにしたほうがいい
    get "/chat_room/private_room", ChatRoomController, :private_room

    resources "/chat_room_log", ChatRoomLogController, except: [:new, :edit]
    resources "/chat_log", ChatsLogController, except: [:new, :edit]
    resources "/chat_member_log", ChatMemberLogController, except: [:new, :edit]
    resources "/assistant_log", AssistantLogController, except: [:new, :edit]
    resources "/entrant_log", EntrantLogController

    resources "/tournament", TournamentController, except: [:new, :edit, :index, :show, :delete]
    post "/tournament/edit", TournamentController, :update
    get "/tournament/users_for_add_assistant", TournamentController, :get_users_for_add_assistant
    get "/tournament/get", TournamentController, :show
    get "/tournament/get_by_master_id", TournamentController, :get_tournaments_by_master_id
    get "/tournament/get_planned", TournamentController, :get_planned_tournaments_by_master_id
    # get  "/tournament/get_planned", TournamentController, :get_ongoing_tournaments_by_master_id
    get "/tournament/get_entrants", TournamentController, :get_entrants
    get "/tournament/by_url", TournamentController, :get_tournament_by_url
    get "/tournament/get_opponent", TournamentController, :get_opponent
    get "/tournament/fighting_users", TournamentController, :get_fighting_users
    get "/tournament/waiting_users", TournamentController, :get_waiting_users
    get "/tournament/data_for_ios", TournamentController, :get_started_match_information
    get "/tournament/match_info", TournamentController, :get_match_information
    get "/tournament/count_tournament_per_month", TournamentController, :count_tournament_per_month
    get "/tournament/leader_info", TournamentController, :get_leader_info

    get "/tournament/entry_template", EntryController, :get_template
    get "/tournament/entry_info", EntryController, :get_entry_information
    get "/tournament/has_entry_info", EntryController, :has_entry_info
    post "/tournament/entry_info", EntryController, :create_entry_information
    post "/tournament/entry_template", EntryController, :create_template
    post "/tournament/edit_brackets", TournamentController, :edit_brackets

    get "/tournament/get_participating_tournaments",
        TournamentController,
        :participating_tournaments

    get "/tournament/is_started_at_least_one", TournamentController, :is_started_at_least_one
    get "/tournament/participating", TournamentController, :participating_tournaments
    get "/tournament/get_tabs", TournamentController, :tournament_topics
    get "/tournament/get_thumbnail", TournamentController, :get_thumbnail_image

    get "/tournament/get_match_list", TournamentController, :get_match_list
    get "/tournament/get_round_robin_match_list", TournamentController, :get_round_robin_match_list
    get "/tournament/home", TournamentController, :home
    get "/tournament/home/search", TournamentController, :search
    get "/tournament/masters", TournamentController, :get_game_masters
    get "/tournament/members", TournamentController, :get_match_members
    get "/tournament/find_match", TournamentController, :find_match
    get "/tournament/check_pending", TournamentController, :check_pending
    get "/tournament/brackets", TournamentController, :brackets_with_fight_result
    get "/tournament/brackets_with_score", TournamentController, :bracket_data_for_best_of_format

    get "/tournament/chunk_brackets_with_score",
        TournamentController,
        :chunk_bracket_data_for_best_of_format

    get "/tournament/duplicate_claims", TournamentController, :get_duplicate_claim_members
    get "/tournament/is_user_win", TournamentController, :is_user_win
    get "/tournament/score", TournamentController, :score
    get "/tournament/relevant", TournamentController, :relevant
    get "/tournament/is_able_to_join", TournamentController, :is_able_to_join
    get "/tournament/has_lost", TournamentController, :has_lost?
    get "/tournament/state", TournamentController, :state
    get "/tournament/pid", TournamentController, :get_pid
    get "/tournament/verify_password", TournamentController, :verify_password
    get "/tournament/pending", TournamentController, :pending
    get "/tournament/url/:url", TournamentController, :redirect_by_url
    get "/tournament/maps", TournamentController, :maps
    get "/tournament/map_icon", TournamentController, :get_map_icon

    post "/tournament/start", TournamentController, :start
    post "/tournament/register/pid", TournamentController, :register_pid_of_start_notification
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
    post "/tournament/claim_score", TournamentController, :claim_score
    post "/tournament/flip_coin", TournamentController, :flip_coin
    post "/tournament/defeat", TournamentController, :force_to_defeat
    post "/tournament/finish", TournamentController, :finish
    post "/tournament/finish_with_result", TournamentController, :finish_with_result
    post "/tournament/ban_maps", TournamentController, :ban_maps
    post "/tournament/choose_map", TournamentController, :choose_map
    post "/tournament/choose_ad", TournamentController, :choose_ad
    post "/tournament/generate_brackets", TournamentController, :generate_brackets
    put "/tournament/update", TournamentController, :update
    post "/tournament/regenerate_round_robin", TournamentController, :rematch_round_robin_as_needed
    post "/tournament/create_assistants", TournamentController, :create_assistants
    post "/tournament/create_categories", FreeForAllController, :create_categories
    delete "/tournament/assistant", TournamentController, :delete_assistant

    get "/tournament_log/index", TournamentLogController, :index
    post "/tournament_log/add", TournamentLogController, :create

    get "/entrant/rank", EntrantController, :show_rank
    resources "/entrant", EntrantController, except: [:new, :edit, :delete]
    # FIXME: GETのパラメータの渡し方を統一したい
    get "/entrant/rank/:tournament_id/:user_id", EntrantController, :show_rank
    delete "/entrant/delete", EntrantController, :delete
    resources "/entrant_log", EntrantLogController
    post "/entrant/rank/promote", EntrantController, :promote

    get "/team", TeamController, :show
    get "/team/teams", TeamController, :get_teams
    get "/team/mates", TeamController, :get_teammates
    get "/team/confirmed_teams", TeamController, :get_confirmed_teams
    get "/team/confirmed_teams_without_members", TeamController, :get_confirmed_teams_without_members
    post "/team", TeamController, :create
    post "/team/resend_invitations", TeamController, :resend_team_invitations
    post "/team/invitation_confirm", TeamController, :confirm_invitation
    post "/team/invitation_decline", TeamController, :decline_invitation
    post "/team/add_members", TeamController, :add_members
    delete "/team", TeamController, :delete

    resources "/assistant", AssistantController, except: [:new, :edit, :index, :show, :delete, :update]

    post "/assistant/delete", AssistantController, :delete

    post "/sync", SyncController, :sync

    post "/conf/send_email", ConfNumController, :send_email
    post "/conf/conf_email", ConfNumController, :conf_email

    get "/notification/list", NotifController, :get_list
    post "/notification/create", NotifController, :create
    post "/notification/all", NotifController, :notify_all
    post "/notification_log/create", NotifLogController, :create
    post "/notification/check_all", NotifController, :check_all
    delete "/notification/delete", NotifController, :delete

    post "/load_test/start", LoadTestController, :start
    post "/load_test/stop", LoadTestController, :stop
    get "/load_test/download", LoadTestController, :download

    post "/device/register", DeviceController, :register_token
    post "/device/unregister", DeviceController, :unregister_token

    get "/image/path", ImageController, :get_by_path
    get "/image/get_thumbnail_by_tournament_id", ImageController, :get_thumbnail_by_tournament_id

    get "/tournament/ffa_categories", FreeForAllController, :get_categories
    get "/tournament/ffa_information", FreeForAllController, :get_information
    get "/tournament/ffa_current_status", FreeForAllController, :get_current_status
    get "/tournament/ffa_tables", FreeForAllController, :get_tables
    get "/tournament/ffa_round_information", FreeForAllController, :get_round_information
    get "/tournament/ffa_round_team_information", FreeForAllController, :get_round_team_information
    get "/tournament/ffa_match_information", FreeForAllController, :get_match_information
    get "/tournament/ffa_load_match_information", FreeForAllController, :load_match_information
    get "/tournament/ffa_team_match_information", FreeForAllController, :get_team_match_information
    get "/tournament/ffa_load_team_match_information", FreeForAllController, :load_team_match_information
    get "/tournament/ffa_get_member_match_information", FreeForAllController, :get_member_match_information
    get "/tournament/ffa_load_member_match_information", FreeForAllController, :load_member_match_information
    post "/tournament/ffa_update_information", FreeForAllController, :update_information
    post "/tournament/ffa_update_categories", FreeForAllController, :update_categories
    post "/tournament/ffa_claim_scores", FreeForAllController, :claim_scores

    get "/bracket", BracketController, :get_bracket
    get "/bracket/num", BracketController, :get_number
    get "/bracket/draw", BracketController, :get_brackets_for_draw
    get "/bracket/by_owner_id", BracketController, :get_brackets_by_owner_id
    get "/bracket/logs_by_owner_id", BracketController, :get_bracket_logs_by_owner_id
    get "/bracket/is_url_valid", BracketController, :is_url_valid
    get "/bracket/participants", BracketController, :get_participants
    get "/bracket/is_bronze_match", BracketController, :is_bronze_match?
    get "/bracket/bronze_match_winner", BracketController, :get_bronze_match_winner
    post "/bracket", BracketController, :create_bracket
    post "/bracket/create_participants", BracketController, :create_participants
    post "/bracket/edit_brackets", BracketController, :edit_brackets
    post "/bracket/start", BracketController, :start
    post "/bracket/undo_start", BracketController, :undo_start
    post "/bracket/claim_lose", BracketController, :claim_lose
    post "/bracket/claim_bronze_lose", BracketController, :claim_bronze_lose
    post "/bracket/claim_scores", BracketController, :claim_scores
    post "/bracket/claim_bronze_scores", BracketController, :claim_bronze_scores
    post "/bracket/undo_progress", BracketController, :undo_progress
    post "/bracket/finish", BracketController, :finish
    delete "/bracket", BracketController, :delete
    delete "/bracket/participant", BracketController, :delete_participant

    get "/bracket/tables", BracketController, :get_tables
  end

  scope "/debug", MilkWeb do
    # FIXME: 見た感じ使われてなさそうだったけど、一応残しておいた
    get "/tournament/image", TournamentController, :image
    get "/tournament/debug_match_list", TournamentController, :debug_match_list
    post "/assistant/get", AssistantController, :show

    post "/push_notice", NotifController, :test_push_notice
  end
end
