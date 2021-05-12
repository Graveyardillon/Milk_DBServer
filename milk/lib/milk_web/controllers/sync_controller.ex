defmodule MilkWeb.SyncController do
  use MilkWeb, :controller

  alias Milk.Chat

  # user_idに関連する情報を全て取り出して送信する
  def sync(conn, %{"user_id" => user_id}) do
    chat_list = Chat.sync(user_id)

    render(conn, "chat.json", chat_data: chat_list)
  end
end
