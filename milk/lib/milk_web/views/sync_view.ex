defmodule MilkWeb.SyncView do
  use MilkWeb, :view
  alias MilkWeb.SyncView

  def render("chat.json", %{chat_data: chat_data}) do
    Enum.map(chat_data, fn chat -> 
      %{
        room_id: chat["room_id"],
        chat_data: %{
          id: chat["data"][:id],
          index: chat["data"][:index],
          chat_room_id: chat["data"][:chat_room_id],
          user_id: chat["data"][:user_id],
          word: chat["data"][:word],
          update_time: chat["data"][:update_time]
        }
      }
    end)
  end
end