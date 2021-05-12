defmodule MilkWeb.ChatRoomController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.ChatRoom
  alias Milk.Accounts
  alias Common.Tools

  @doc """
  Create a new chat room.
  """
  def create(conn, %{"chat_room" => chat_room_params}) do
    case Chat.create_chat_room(chat_room_params) do
      {:ok, %ChatRoom{} = chat_room} ->
        conn
        # |> put_status(:created)
        # |> put_resp_header("location", Routes.chat_room_path(conn, :show, chat_room))
        |> render("show.json", chat_room: chat_room)

      {:error, error} ->
        render(conn, "error.json", error: error)

      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get a new chat room information.
  """
  def show(conn, %{"id" => id}) do
    id = Tools.to_integer_as_needed(id)

    chat_room = Chat.get_chat_room(id)

    if chat_room do
      render(conn, "show.json", chat_room: chat_room)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Update a chat room.
  """
  def update(conn, %{"id" => id, "chat_room" => chat_room_params}) do
    chat_room = Chat.get_chat_room(id)

    if chat_room do
      with {:ok, %ChatRoom{} = chat_room} <- Chat.update_chat_room(chat_room, chat_room_params) do
        render(conn, "show.json", chat_room: chat_room)
      else
        _ -> render(conn, "error.json", error: nil)
      end
    else
      # IDが存在しない
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Delete a chat room.
  """
  def delete(conn, %{"id" => id}) do
    chat_room = Chat.get_all_chat(id)

    if chat_room do
      with {:ok, %ChatRoom{}} <- Chat.delete_chat_room(chat_room) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  @doc """
  Get private rooms of a specific user.
  """
  def private_rooms(conn, %{"user_id" => id}) do
    user_id = Tools.to_integer_as_needed(id)

    chat_with_user =
      Chat.get_private_chat_rooms(user_id)
      |> Enum.map(fn room ->
        user = Chat.get_user_in_private_room(room.id, user_id)

        %{
          id: user.id,
          room_id: room.id,
          name: user.name,
          email: user.auth.email,
          last_chat: room.last_chat,
          count: room.count,
          is_private: room.is_private,
          icon_path: user.icon_path
        }
      end)

    if chat_with_user do
      render(conn, "chat_rooms_with_user.json", info: chat_with_user)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def private_room(conn, %{"my_id" => my_id, "partner_id" => partner_id}) do
    my_id = Tools.to_integer_as_needed(my_id)
    partner_id = Tools.to_integer_as_needed(partner_id)
    user = Accounts.get_user(partner_id)

    info =
      case Chat.get_private_chat_room(my_id, partner_id) do
        {:ok, room} ->
          %{
            id: user.id,
            room_id: room.id,
            name: user.name,
            email: user.auth.email,
            last_chat: room.last_chat,
            count: room.count,
            is_private: room.is_private,
            icon_path: user.icon_path
          }

        {:error, _} ->
          {:ok, room} = Chat.create_chat_room(%{name: "%user%", member_count: 2, is_private: 2})
          Chat.create_chat_member(%{"user_id" => my_id, "chat_room_id" => room.id})
          Chat.create_chat_member(%{"user_id" => partner_id, "chat_room_id" => room.id})

          %{
            id: user.id,
            room_id: room.id,
            name: user.name,
            email: user.auth.email,
            last_chat: room.last_chat,
            count: room.count,
            is_private: room.is_private,
            icon_path: user.icon_path
          }
      end

    render(conn, "chat_room_with_user.json", %{info: info})
  end
end
