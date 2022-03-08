defmodule Milk.MessageGenerator.Tournament do
  @moduledoc """
  多言語のメッセージを扱うためのやつ
  """
  def got_invitation_from(user_name, "japanese"),   do: "#{user_name}からチーム招待されました。"
  def got_invitation_from(user_name, "english"),    do: "Received an invitation from #{user_name}."
  def got_invitation_from(user_name, "indonesian"), do: "Menerima undangan dari #{user_name}."
end
