defmodule Milk.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Common.Sperm

  require Logger

  alias Common.Tools

  alias Ecto.Multi

  alias Milk.{
    Accounts,
    Repo,
    Tournaments
  }

  alias Milk.Discord.User, as: DiscordUser

  alias Milk.Accounts.{
    ActionHistory,
    Auth,
    Device,
    ExternalService,
    User
  }

  alias Milk.Chat.{
    ChatRoom,
    ChatMember
  }

  alias Milk.Log.{
    ChatMemberLog,
    AssistantLog,
    EntrantLog
  }

  alias Milk.UserManager.Guardian
  alias Milk.CloudStorage.Objects

  @typedoc """
  User changeset structure.

  The types %User{} and Accounts are equivalent.
  """
  @type t :: %User{}

  @doc """
  Lists all users.
  """
  def list_user(), do: Repo.all(User)

  @doc """
  Gets total user number.
  """
  def get_user_number() do
    Repo.aggregate(User, :count)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user(integer()) :: User.t() | nil
  def get_user(user_id) do
    User
    |> join(:inner, [u], a in Auth, on: u.id == a.user_id)
    |> where([u, a], u.id == ^user_id)
    |> Repo.one()
    |> Repo.preload(:auth)
    |> Repo.preload(:discord)
  end

  @doc """
  Get user by discord id
  # HACK: 複数のアカウントが同じdiscord idを使ってログインすることを想定していない。
  データベースに制約をつけて、associateの処理に変更を加える必要がある。
  """
  def get_user_by_discord_id(discord_id) do
    User
    |> join(:inner, [u], du in DiscordUser, on: u.id == du.user_id)
    |> where([u, du], du.discord_id == ^discord_id)
    |> Repo.one()
  end

  @doc """
  Checks name duplication.
  """
  @spec check_duplication?(binary) :: boolean
  def check_duplication?(name) do
    User
    |> where([u], u.name == ^name)
    |> Repo.exists?()
  end

  @doc """
  Get all users in touch.
  """
  @spec get_users_in_touch(integer) :: list(Accounts.t())
  def get_users_in_touch(id) do
    ChatMember
    |> where([cm], cm.user_id == ^id)
    |> Repo.all()
    |> get_private_rooms()
    |> get_members_in_private_rooms(id)
    |> get_users_by_member_id()
  end

  defp get_private_rooms(members) do
    Enum.map(members, fn member ->
      ChatRoom
      |> where([cr], cr.is_private and cr.id == ^member.chat_room_id)
      |> Repo.one()
    end)
  end

  defp get_members_in_private_rooms(rooms, my_id) do
    Enum.map(rooms, fn room ->
      ChatMember
      |> where([cm], cm.chat_room_id == ^room.id and cm.user_id != ^my_id)
      |> Repo.all()
      ~> users

      unless length(users) == 1, do: Logger.warn("get_all_users_in_touch/1 gets too big list")
      hd(users)
    end)
  end

  defp get_users_by_member_id(members) do
    Enum.map(members, fn member ->
      Repo.one(
        from u in User,
          join: a in assoc(u, :auth),
          where: u.id == ^member.user_id,
          preload: [auth: a]
      )
    end)
  end

  @doc """
  Checks if given email address exists.
  """
  def email_exists?(email) do
    Auth
    |> where([a], a.email == ^email)
    |> Repo.exists?()
  end

  @doc """
  Creates a user.
  """
  @spec create_user(map, binary) :: tuple()
  def create_user(attrs, service_name \\ "e-players") do
    attrs = put_id_for_show(attrs)

    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Multi.insert(:auth, fn %{user: user} ->
      apply_changeset_of_oauth(user, attrs, service_name)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, user} -> {:ok, Map.put(user.user, :auth, %Auth{email: user.auth.email})}
      {:error, _, error, _data} -> {:error, error.errors}
      _ -> {:error, nil}
    end
  end

  defp put_id_for_show(attrs) do
    case attrs do
      %{"id_for_show" => id} ->
        Map.put(attrs, "id_for_show", generate_id_for_show(id))

      _ ->
        Map.put(attrs, "id_for_show", generate_id_for_show())
    end
  end

  defp generate_id_for_show() do
    0..999_999
    |> Enum.random()
    |> generate_id_for_show()
  end

  defp generate_id_for_show(1_000_000), do: generate_id_for_show(0)

  defp generate_id_for_show(tmp_id) do
    User
    |> where([u], u.id_for_show == ^tmp_id)
    |> Repo.exists?()
    |> unless do
      tmp_id
    else
      generate_id_for_show(tmp_id + 1)
    end
  end

  defp apply_changeset_of_oauth(user, attrs, "e-players") do
    user
    |> Ecto.build_assoc(:auth)
    |> Auth.changeset(attrs)
  end

  defp apply_changeset_of_oauth(user, attrs, service_name) do
    user
    |> Map.put("service_name", service_name)
    |> Ecto.build_assoc(:auth)
    |> Auth.changeset_oauth(attrs)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, error}
  """
  @spec update_user(Accounts.t(), map) :: tuple()
  def update_user(%User{} = user, attrs) do
    Multi.new()
    |> Multi.update(:user, fn _ ->
      User.changeset(user, attrs)
    end)
    |> Multi.update(:auth, fn _ ->
      Auth.changeset_update(user.auth, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, user} -> {:ok, user.user}
      {:error, _, error, _data} -> {:error, error.errors}
      _ -> {:error, nil}
    end
  end

  @doc """
  Change a password.
  """
  def change_password_by_email(email, new_password) do
    email
    |> get_user_by_email()
    |> Map.get(:auth)
    |> Auth.changeset(%{password: new_password})
    |> Repo.update()
  end

  def get_user_by_email(email) do
    User
    |> join(:inner, [u], a in assoc(u, :auth))
    |> where([u, a], a.email == ^email)
    |> preload([u, a], auth: a)
    |> Repo.one()
  end

  @doc """
  Search users.
  """
  def search(text) do
    like = "%#{text}%"

    from(
      u in User,
      where: like(u.name, ^like),
      preload: [:auth]
    )
    |> Repo.all()
  end

  @doc """
  Updates an icon.
  """
  @spec update_icon_path(Accounts.t(), binary) :: tuple()
  def update_icon_path(user, icon_path) do
    old_icon_path = Repo.one(from u in User, where: u.id == ^user.id, select: u.icon_path)

    unless is_nil(old_icon_path) do
      case Application.get_env(:milk, :environment) do
        # coveralls-ignore-start
        :dev ->
          rm(old_icon_path)

        :test ->
          rm(old_icon_path)

        _ ->
          rm_prod(old_icon_path)
          # coveralls-ignore-stop
      end
    end

    user
    |> User.changeset(%{icon_path: icon_path})
    |> Repo.update()
  end

  defp rm(old_icon_path) do
    File.rm("./static/image/profile_icon/#{old_icon_path}.jpg")
  end

  defp rm_prod(old_icon_path) do
    # coveralls-ignore-start
    Objects.delete(old_icon_path)
    # coveralls-ignore-stop
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(integer, binary, binary, binary) :: tuple()
  def delete_user(id, password, email, token) do
    user = get_authorized_user(id, password, email, token)

    if user && !is_binary(user) do
      if is_list(user.chat_member) do
        Enum.map(user.chat_member, fn x ->
          %{
            chat_room_id: x.chat_room_id,
            user_id: x.user_id,
            authority: x.authority,
            create_time: x.create_time,
            update_time: x.update_time
          }
        end)
        ~> member

        Repo.insert_all(ChatMemberLog, member)

        Repo.update_all(
          from(cr in Milk.Chat.ChatRoom,
            join: cm in assoc(cr, :chat_member),
            where: cm.user_id == ^user.id,
            update: [set: [member_count: cr.member_count - 1]]
          ),
          []
        )
      end

      if is_list(user.entrant) do
        Enum.map(user.entrant, fn x ->
          %{
            user_id: x.user_id,
            tournament_id: x.tournament_id,
            rank: x.rank,
            create_time: x.create_time,
            update_time: x.update_time
          }
        end)
        ~> entrant

        Repo.insert_all(EntrantLog, entrant)

        Repo.update_all(
          from(t in Milk.Tournaments.Tournament,
            join: e in assoc(t, :entrant),
            where: e.user_id == ^user.id,
            update: [set: [count: t.count - 1]]
          ),
          []
        )
      end

      if is_list(user.chat_member) do
        assistant =
          Enum.map(user.assistant, fn x ->
            %{
              user_id: x.user_id,
              tournament_id: x.tournament_id,
              create_time: x.create_time,
              update_time: x.update_time
            }
          end)

        Repo.insert_all(AssistantLog, assistant)
      end

      delete(user)
    else
      {:error, user}
    end
  end

  # テスト用に分離しただけなので、基本的にはdelete_userから呼び出すべき関数
  def delete(user) do
    user.id
    |> Tournaments.get_participating_tournaments()
    |> Enum.each(fn tournament ->
      Tournaments.delete_loser_process(tournament.id, [user.id])
    end)

    Repo.delete(user)
  end

  defp get_authorized_user(id, password, email, token) do
    token
    |> Guardian.decode_and_verify()
    |> case do
      {:ok, _claims} ->
        Repo.one(
          from u in User,
            join: a in assoc(u, :auth),
            left_join: cm in assoc(u, :chat_member),
            left_join: as in assoc(u, :assistant),
            left_join: e in assoc(u, :entrant),
            where:
              u.id == ^id and
                a.email == ^email,
            preload: [auth: a, chat_member: cm, entrant: e, assistant: as]
        )

      {:error, :token_expired} ->
        token
        |> Guardian.signout()
        |> if do
          "That token is expired"
        else
          "That token does not exist"
        end

      {:error, :not_exist} ->
        "That token can't use"

      _ ->
        "That token does not exist"
    end
    |> case do
      %User{} = user ->
        password
        |> Argon2.verify_pass(user.auth.password)
        |> if do
          user
        else
          nil
        end

      x ->
        x
    end
  end

  # logout_flのないバージョン
  @doc """
  Login function.
  """
  # @spec login(map | nil) :: {:ok, _, binary} | {:error, nil, nil}
  @spec login(map) :: tuple()
  def login(user) do
    password = user["password"]

    user["email_or_username"]
    |> String.match?(~r/^[[:word:]\-._]+@[[:word:]\-_.]+\.[[:alpha:]]+$/)
    |> if do
      get_valid_user(user, password, :email)
    else
      get_valid_user(user, password, :username)
    end
    |> case do
      %User{} = user ->
        user
        |> User.changeset(%{logout_fl: false})
        |> Repo.update()

      _ ->
        {:error, nil}
    end
  end

  defp get_valid_user(user, password, mode) do
    User
    |> join(:inner, [u], a in assoc(u, :auth))
    |> where_mode(mode, user)
    |> preload([u, a], auth: a)
    |> Repo.one()
    |> case do
      %User{} = userinfo ->
        if Argon2.verify_pass(password, userinfo.auth.password), do: userinfo

      nil ->
        case mode do
          :email -> get_valid_user(user, password, :username)
          _ -> nil
        end
    end
  end

  defp where_mode(query, :email, user) do
    where(query, [u, a], a.email == ^user["email_or_username"])
  end

  defp where_mode(query, :username, user) do
    where(query, [u, a], u.name == ^user["email_or_username"])
  end

  @doc """
  Force to login.
  """
  def login_forced(user) do
    user = get_valid_user(%{"email_or_username" => user["email"]}, user["password"], :email)

    if user do
      user
      |> User.changeset(%{logout_fl: false})
      |> Repo.update()
    end

    user
  end

  @doc """
  Logout function
  """
  def logout(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> where([u], not u.logout_fl)
    |> Repo.one()
    ~> user
    |> if do
      user
      |> User.changeset(%{logout_fl: true})
      |> Repo.update()
    else
      {:error, "user does not exist"}
    end
  end

  @doc """
  Create an action history.
  """
  def create_action_history(attrs) do
    %ActionHistory{}
    |> ActionHistory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gain 5 score.
  レコメンドシステム用にスコアを取得する関数
  """
  def gain_score(%{"user_id" => user_id, "game_name" => game_name, "score" => gain}) do
    %{"user_id" => user_id, "game_name" => game_name, "gain" => gain}
    |> create_action_history()
  end

  @doc """
  Get a device.
  """
  def get_device(device_id) do
    Device
    |> where([d], d.token == ^device_id)
    |> Repo.one()
  end

  @doc """
  Get devices by user id.
  """
  def get_devices_by_user_id(user_id) do
    Device
    |> where([d], d.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Register a device token.
  TODO: update処理
  """
  def register_device(user_id, token) do
    attrs = %{"user_id" => user_id, "token" => token}

    with {:ok, device} <-
           %Device{}
           |> Device.changeset(attrs)
           |> Repo.insert() do
      {:ok, device}
    else
      {:error, error} -> {:error, Tools.create_error_message(error.errors)}
    end
  end

  @doc """
  Unregister a device token.
  """
  def unregister_device(%Device{} = device) do
    device
    |> Repo.delete()
    |> case do
      {:ok, _device} -> true
      {:error, _error} -> false
    end
  end

  # TODO: profile更新

  @doc """
  Create external service.
  """
  def create_external_service(attrs) do
    %ExternalService{}
    |> ExternalService.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get external service.
  """
  def get_external_service(id) do
    Repo.get(ExternalService, id)
  end

  @doc """
  Get external services by user id.
  """
  def get_external_services(user_id) do
    ExternalService
    |> where([es], es.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Update external service.
  """
  def update_external_service(%ExternalService{} = external_service, attrs) do
    external_service
    |> ExternalService.changeset(attrs)
    |> Repo.update()
  end

  def delete_external_service(external_service_id) do
    external_service_id
    |> get_external_service()
    |> Repo.delete()
  end
end
