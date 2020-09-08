defmodule MilkWeb.SyncView do
  use MilkWeb, :view
  alias MilkWeb.SyncView
  alias MilkWeb.Chats

  def render("chat.json", %{chat_data: chat_data}) do
    map = Enum.map(chat_data, fn chat -> 
      IO.inspect(chat["data"])
      %{
        room_id: chat["room_id"],
        chat_data: Enum.map(chat["data"], fn chat_content ->
          %{
            id: chat_content.id,
            index: chat_content.index,
            chat_room_id: chat_content.chat_room_id,
            user_id: chat_content.user_id,
            word: chat_content.word,
            update_time: chat_content.update_time
          }
        end)
      }
    end)

    %{data: map}
  end
end