defmodule Milk.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  require Logger

  alias Milk.Repo
  alias Ecto.Multi
  alias Milk.UserManager.Guardian
  alias Milk.Accounts.{User, Auth}
  alias Milk.Chat.{ChatRoom, ChatMember}
  alias Milk.Log.{ChatMemberLog, AssistantLog, EntrantLog}

  @typedoc """
  User changeset structure.

  The types %User{} and Accounts are equivalent.
  """
  @type t :: %User{}

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user(integer) :: Accounts.t
  def get_user(id), do: Repo.one(from u in User, join: a in assoc(u, :auth), where: u.id == ^id, preload: [auth: a])

  @doc """
  Get all users in touch.
  """
  @spec get_users_in_touch(integer) :: []
  def get_users_in_touch(id) do
    ChatMember
    |> where([cm], cm.user_id == ^id)
    |> Repo.all()
    |> get_private_rooms()
    |> get_members_in_private_rooms(id)
    |> get_users_by_member_id()
  end

  # FIXME: Chatの方に移した方がいいかもしれない
  defp get_private_rooms(members) do
    Enum.map(members, fn member ->
      ChatRoom
      |> where([cr], cr.is_private and cr.id == ^member.chat_room_id)
      |> Repo.one()
    end)
  end

  defp get_members_in_private_rooms(rooms, my_id) do
    Enum.map(rooms, fn room ->
      users =
        ChatMember
        |> where([cm], cm.chat_room_id == ^room.id and cm.user_id != ^my_id)
        |> Repo.all()

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

  # Gets id_for_show.
  defp generate_random_id() do
    Enum.random(0..999999)
    |> generate_random_id()
  end
  defp generate_random_id(tmp_id) when tmp_id > 999999 do
    generate_random_id(0)
  end
  defp generate_random_id(tmp_id) do
    unless Repo.exists?(from u in User, where: u.id_for_show == ^tmp_id) do
      tmp_id
    else
      generate_random_id(tmp_id + 1)
    end
  end

  @doc """
  Creates a user.
  """
  def create_user(without_id_attrs \\ %{}) do
    attrs = Map.put(without_id_attrs, "id_for_show", generate_random_id())

    Multi.new
    |> Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Multi.insert(:auth, fn(%{user: user}) ->
      Ecto.build_assoc(user, :auth)
      |> Auth.changeset(attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, user} -> {:ok, Map.put(user.user, :auth, %Auth{email: user.auth.email})}
      {:error, _, error, _data} -> {:error, error.errors}
      _ -> {:error, nil}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, error}
  """
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
  Updates an icon.
  """
  def update_icon_path(user, icon_path) do
    old_icon_path = Repo.one(from u in User, where: u.id == ^user.id, select: u.icon_path)
    unless is_nil(old_icon_path) do
      File.rm("./static/image/profile_icon/#{old_icon_path}.png")
    end

    Repo.update(Ecto.Changeset.change user, icon_path: icon_path)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(id, password, email, token) do
    user = get_authorized_user(id, password, email, token)
    if is_list(user.chat_member) do
      member = Enum.map(user.chat_member, fn x -> %{chat_room_id: x.chat_room_id, user_id: x.user_id, authority: x.authority, create_time: x.create_time, update_time: x.update_time} end)
      Repo.insert_all(ChatMemberLog, member)
      Repo.update_all(from(cr in Milk.Chat.ChatRoom, join: cm in assoc(cr, :chat_member), where: cm.user_id == ^user.id, update: [set: [member_count: cr.member_count - 1]]),[])
    end

    if is_list(user.entrant) do
      entrant = Enum.map(user.entrant, fn x -> %{user_id: x.user_id, tournament_id: x.tournament_id, rank: x.rank, create_time: x.create_time, update_time: x.update_time} end)
      Repo.insert_all(EntrantLog, entrant)
      Repo.update_all(from(t in Milk.Tournaments.Tournament, join: e in assoc(t, :entrant), where: e.user_id == ^user.id, update: [set: [count: t.count - 1]]), [])
    end

    if is_list(user.chat_member) do
      assistant = Enum.map(user.assistant, fn x -> %{user_id: x.user_id, tournament_id: x.tournament_id, create_time: x.create_time, update_time: x.update_time} end)
      Repo.insert_all(AssistantLog, assistant)
    end

    Repo.delete(user)
  end

  defp get_authorized_user(id, password, email, token) do
    case Guardian.decode_and_verify(token) do
      {:ok, _} ->
        Repo.one(
          from u in User,
          join: a in assoc(u, :auth),
          left_join: cm in assoc(u, :chat_member),
          left_join: as in assoc(u, :assistant),
          left_join: e in assoc(u, :entrant),
          where:
            u.id == ^id
            and a.password == ^password
            and a.email == ^email,
          preload: [auth: a, chat_member: cm, entrant: e, assistant: as]
        )
      #FIXME: エラーハンドリングが適当すぎる
      {:error, :token_expired} ->
        Guardian.signout(token)
        |> if do
          "That token is out of time"
        else
          "That token is not exist"
        end
      {:error, :not_exist} ->
        "That token can't use"
      _ ->
        "That token is not exist"
      end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  # logout_flのないバージョン
  @doc """
  Login function.
  """
  def login(user) do
    password = user["password"]
    # usernameかemailか
    if String.match?(user["email_or_username"], ~r/^[[:word:]\-._]+@[[:word:]\-_.]+\.[[:alpha:]]+$/) do
      get_valid_user(user, password, :email)
    else
      get_valid_user(user, password, :username)
    end
    |> case do
      %User{} = user ->
        {:ok, userinfo} =
          user
          |> User.changeset(%{logout_fl: false})
          |> Repo.update()
        {:ok, token, _} =
          Guardian.encode_and_sign(userinfo, %{}, token_type: "refresh", ttl: {4, :weeks})
        %{user: userinfo, token: token}
      _ -> nil
    end
  end

  defp where_mode(query, :email, user) do
    where(query, [u,a], a.email == ^user["email_or_username"])
  end
  defp where_mode(query, :username, user) do
    where(query, [u,a], a.name == ^user["email_or_username"])
  end
  defp get_valid_user(user, password, mode) do
    User
    |> join(:inner, [u], a in assoc(u, :auth))
    |> where_mode(mode, user)
    |> preload([u,a], [auth: a])
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
  # def login(user) do
  #   password = Auth.create_pass(user["password"])
  #   #usernameかemailか
  #   if String.match?(user["email_or_username"], ~r/^[[:word:]\-._]+@[[:word:]\-_.]+\.[[:alpha:]]+$/) do
  #     case Repo.one(from u in User, join: a in assoc(u, :auth), where: a.email == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a]) do
  #       nil -> Repo.one(from u in User, join: a in assoc(u, :auth), where: a.name == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a])
  #       %User{} = userinfo -> userinfo
  #     end
  #   else
  #     Repo.one(from u in User, join: a in assoc(u, :auth), where: a.name == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a])
  #   end
  #   |>case do
  #     %User{} = user ->
  #       user
  #       |> User.changeset(%{logout_fl: false})
  #       |> Repo.update
  #       user
  #     _ -> nil
  #   end
  # end

  def login_forced(user) do
    password = Auth.create_pass(user["password"])

    user = Repo.one(from u in User, join: a in assoc(u, :auth), where: a.email == ^user["email"] and a.password == ^password, preload: [auth: a])
    if(user) do
      user
      |> User.changeset(%{logout_fl: false})
      |> Repo.update
    end
    user
  end

  @doc """
  Logout function
  """
  def logout(id) do
    user = Repo.one(from u in User,where: u.id ==  ^id and not u.logout_fl)
    if(user) do
      user
      |> User.changeset(%{logout_fl: true})
      |> Repo.update

      true
    else
      false
    end
  end

  @doc """
  Creates a auth.

  ## Examples

      iex> create_auth(%{field: value})
      {:ok, %Auth{}}

      iex> create_auth(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_auth(attrs \\ %{}) do
    %Auth{}
    |> Auth.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a auth.

  ## Examples

      iex> update_auth(auth, %{field: new_value})
      {:ok, %Auth{}}

      iex> update_auth(auth, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_auth(%Auth{} = auth, attrs) do
    auth
    |> Auth.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a auth.

  ## Examples

      iex> delete_auth(auth)
      {:ok, %Auth{}}

      iex> delete_auth(auth)
      {:error, %Ecto.Changeset{}}

  """
  def delete_auth(%Auth{} = auth) do
    Repo.delete(auth)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking auth changes.

  ## Examples

      iex> change_auth(auth)
      %Ecto.Changeset{source: %Auth{}}

  """
  def change_auth(%Auth{} = auth) do
    Auth.changeset(auth, %{})
  end
end