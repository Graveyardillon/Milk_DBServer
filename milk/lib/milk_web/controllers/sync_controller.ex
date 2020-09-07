defmodule MilkWeb.SyncController do
  use MilkWeb, :controller

  alias Milk.Chat

  # user_idに関連する情報を全て取り出して送信する
  def sync(conn, %{"user_id" => user_id}) do
    chat_list = obtain_chat(user_id)

    json(conn, %{"msg" => "ok"})
  end

  defp obtain_chat(user_id) do
    
  end
end