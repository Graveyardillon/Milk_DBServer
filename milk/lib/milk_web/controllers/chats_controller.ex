defmodule MilkWeb.ChatsController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.Chats
  alias Milk.Media.Image
  alias Milk.CloudStorage.Objects

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
    if chats do
      with {:ok, %Chats{}} <- Chat.delete_chats(chats) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  @doc """
  Upload a image.
  FIXME: chatディレクトリがない場合は作成の処理入れたいな
  """
  def upload_image(conn, %{"image" => image}) do
    image_path = if image != "" do
      uuid = SecureRandom.uuid()
      File.cp(image.path, "./static/image/chat/#{uuid}.jpg")
      case Application.get_env(:milk, :environment) do
        :dev -> uuid
        :test -> uuid
        _ ->
          object = Milk.CloudStorage.Objects.upload("./static/image/chat/#{uuid}.jpg")
          File.rm("./static/image/chat/#{uuid}.jpg")
          object.name
      end
    else
      nil
    end
    json(conn, %{local_path: image_path})
  end

  @doc """
  Load image.
  """
  def load_image(conn, %{"id" => id, "path" => name}) do
    map = case Application.get_env(:milk, :environment) do
      :dev -> loadimg(name)
      :test -> loadimg(name)
      _ -> loadimg_prod(name)
    end

    json(conn, map)
  end

  defp loadimg(name) do
    case File.read("./static/image/chat/#{name}.jpg") do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}
      {:error, _} ->
        %{error: "image not found"}
    end
  end

  defp loadimg_prod(name) do
    object = Objects.get(name)
    case Image.get(object.mediaLink) do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}
      _ ->
        %{error: "image not found"}
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
