defmodule MilkWeb.ChatsController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.Chats

  @doc """
  Create a new chat.
  """
  def create(conn, %{"chat" => chats_params}) do
    case Chat.create_chats(chats_params) do
      {:ok, %Chats{} = chats} ->
        render(conn, "show.json", chats: chats)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get an information of a chat.
  """
  def show(conn, %{"id" => id}) do
    chats = Chat.get_chats!(id)
    if (chats) do
      render(conn, "show.json", chats: chats)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Update a chat information.
  """
  def update(conn, %{"id" => id, "chat" => chats_params}) do
    chats = Chat.get_chats!(id)
    if (chats) do
      with {:ok, %Chats{} = chats} <- Chat.update_chats(chats, chats_params) do
        render(conn, "show.json", chats: chats)
      else
        _ -> render(conn, "error.json", error: nil)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Delete a chat.
  """
  def delete(conn, %{"chat_room_id" => chat_room_id, "index" => index}) do
    chats = Chat.get_chat(chat_room_id, index)
    if (chats) do
      with {:ok, %Chats{}} <- Chat.delete_chats(chats) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  @doc """
  Utility function.
  If the user does not have any rooms for partner user,
  it creates a new room and then send a chat.
  If the user already have a room for him,
  it doesn't create a room but just send a chat.
  """
  def create_dialogue(conn, %{"chat" => chats_params}) do
    case Chat.dialogue(chats_params) do
      {:ok, %Chats{} = chats} ->
        conn
        |> render("show.json", chats: chats)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  def create_dialogue(conn, %{"chat_group" => chats_params}) do
    case Chat.dialogue(chats_params) do
      {:ok, %Chats{} = chats} ->
        members = Chat.get_chat_members_of_room(chats.chat_room_id)
                  |> Enum.map(fn member ->
                    member.id
                  end)

        conn
        |> render("show.json", chats: chats, members: members)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end
end
