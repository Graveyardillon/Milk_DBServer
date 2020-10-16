defmodule Milk.Accounts do
  @moduledoc """
  The Accounts context.
  """
  
  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Accounts.User
  alias Milk.Accounts.Auth
  alias Milk.Log.{ChatMemberLog, AssistantLog, EntrantLog}
  alias Milk.Chat.{ChatRoom, ChatMember}
  alias Ecto.Multi
  
  require Logger

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(from u in User, join: a in assoc(u, :auth), order_by: u.create_time, preload: [auth: a])
  end

  def list_usernames do
    User
    |> select([u], u.name)
    |> Repo.all()
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
  def get_user(id), do: Repo.one(from u in User, join: a in assoc(u, :auth), where: u.id == ^id, preload: [auth: a])

  @doc """
  Get all users in touch
  """
  def get_all_users_in_touch(id) do
    ChatMember
    |> where([cm], cm.id == ^id)
    |> Repo.all()
    |> Enum.map(fn member -> 
      ChatRoom
      |> where([cr], cr.is_private and cr.id == ^member.chat_room_id)
      |> Repo.one()
    end)
    |> Enum.map(fn room -> 
      users = 
        ChatMember
        |> where([cm], cm.chat_room_id == ^room.id and cm.id != ^id)
        |> Repo.all()
      
      unless length(users) == 1, do: Logger.warn("get_all_users_in_touch/1 gets too big list")
      hd(users)
    end)
    |> Enum.map(fn member -> 
      Repo.one(
        from u in User, 
        join: a in assoc(u, :auth),
        where: u.id == ^member.user_id,
        preload: [auth: a]
      )
    end)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # def create_user(attrs \\ %{}) do
  #   {:ok, user} = %User{}
  #                 |> User.changeset(attrs)
  #                 |> user_check()
    
  #   if(user) do
  #     user
  #       |> Ecto.build_assoc(:auth)
  #       |> Auth.changeset(attrs)
  #       |> auth_check(user)
  #   end
  # end

  # def user_check(chgst) do
  #   if (chgst.valid?) do
  #     Repo.insert(chgst)
  #   else
  #     {:ok, false}
  #   end
  # end

  # def auth_check(chgst, user) do
  #   if (chgst.valid?) do
  #     with {:ok, _} <- Repo.insert(chgst) do
  #       {:ok, user}
  #     else
  #       _ -> Repo.delete user
  #         {:error, nil}
  #     end
  #   else 
  #     Repo.delete user
  #     {:error, nil}
  #   end
  # end

  def create_user(attrs \\ %{}) do
      case Multi.new
      |> Multi.insert(:user, User.changeset(%User{}, attrs))
      |> Multi.insert(:auth, fn(%{user: user}) ->
        Ecto.build_assoc(user, :auth)
        |> Auth.changeset(attrs)
      end)
      |> Repo.transaction() do
        {:ok, user} -> {:ok, user.user}
        {:error, _, error, _data} -> {:error, error.errors}
        _ -> {:ok, nil}
      end
    end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # def update_user(%User{} = user, attrs) do
    
  #   with {:error, _} <- user.auth
  #                     |> Auth.changeset_update(attrs)
  #                     |> Repo.update()
  #   do
  #     Auth.changeset(user.auth, %{})
  #     |> Repo.update()
  #     {:error, nil}
  #   else
  #     _ ->
  #       user
  #       |> User.changeset(attrs)
  #       |> Repo.update()
  #   end
  # end

  def update_user(%User{} = user, attrs) do
    case Multi.new()
    |> Multi.update(:user, fn _ ->
      User.changeset(user, attrs)
    end)
    |> Multi.update(:auth, fn _ ->
      Auth.changeset_update(user.auth, attrs)
    end)
    |> Repo.transaction() do
      {:ok, user} -> {:ok, user.user}
      {:error, _, error, _data} -> {:error, error.errors}
      _ -> {:ok, nil}
    end
  end

  def update_icon_path(user, icon_path) do
    old_icon_path = Repo.one(from u in User, where: u.id == ^user.id, select: u.icon_path)
    if old_icon_path != nil do
      File.rm("./static/image/profile_icon/#{old_icon_path}.png")
    end

    Repo.update(Ecto.Changeset.change user, icon_path: icon_path)
  end

  def check_user(id, password, email) do
    Repo.one(from u in User, 
    join: a in assoc(u, :auth), 
    left_join: cm in assoc(u, :chat_member),
    left_join: as in assoc(u, :assistant),
    left_join: e in assoc(u, :entrant),
    where: u.id == ^id
    and a.password == ^password
    and a.email == ^email, 
    preload: [auth: a, chat_member: cm, entrant: e, assistant: as])
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """

  def delete_user(%User{} = user) do
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

  def tru(id) do
    IO.inspect id
    true
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

  def login(user) do
    password = Auth.create_pass(user["password"])
    #usernameかemailか
    if String.match?(user["email_or_username"],~r/^[[:word:]\-._]+@[[:word:]\-_.]+\.[[:alpha:]]+$/) do
      case Repo.one(from u in User, join: a in assoc(u, :auth), where: a.email == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a]) do
        nil -> Repo.one(from u in User, join: a in assoc(u, :auth), where: a.name == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a])
        %User{} = userinfo -> userinfo
      end
    else
      Repo.one(from u in User, join: a in assoc(u, :auth), where: a.name == ^user["email_or_username"] and a.password == ^password and u.logout_fl, preload: [auth: a])
    end
    |>case do
      %User{} = user ->
        user
        |> User.changeset(%{logout_fl: false})
        |> Repo.update
        user
      _ -> nil
    end
  end

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
  Returns the list of auth.

  ## Examples

      iex> list_auth()
      [%Auth{}, ...]

  """
  def list_auth do
    Repo.all(Auth)
  end

  @doc """
  Gets a single auth.

  Raises `Ecto.NoResultsError` if the Auth does not exist.

  ## Examples

      iex> get_auth!(123)
      %Auth{}

      iex> get_auth!(456)
      ** (Ecto.NoResultsError)

  """
  def get_auth(id), do: Repo.get(Auth, id)

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