defmodule Milk.MessageGenerator.Tournament do
  @moduledoc """
  多言語のメッセージを扱うためのやつ
  """

  @default_lang "english"

  def got_invitation_from(name, "japanese"),   do: "#{name}からチーム招待されました。"
  def got_invitation_from(name, "english"),    do: "Received an invitation from #{name}."
  def got_invitation_from(name, "indonesian"), do: "Menerima undangan dari #{name}."
  def got_invitation_from(name, _),            do: __MODULE__.got_invitation_from(name, @default_lang)

  def joined_team(name, "japanese"),   do: "#{name}がチームに参加しました。"
  def joined_team(name, "english"),    do: "#{name} joined your team."
  def joined_team(name, "indonesian"), do: "#{name} bergabung dengan tim Anda."
  def joined_team(name, _),            do: __MODULE__.joined_team(name, @default_lang)

  def reject_team_invitation(name, "japanese"),   do: "#{name}がチームへの招待を辞退しました。"
  def reject_team_invitation(name, "english"),    do: "#{name} rejected your team invitation."
  def reject_team_invitation(name, "indonesian"), do: "#{name} menolak undangan timmu."
  def reject_team_invitation(name, _),            do: __MODULE__.reject_team_invitation(name, @default_lang)

  def received_discord_server_invitation_of(name, "japanese"),   do: "#{name}のDiscordサーバーへの招待を受け取りました。"
  def received_discord_server_invitation_of(name, "english"),    do: "Received an invitation of #{name}'s discord server."
  def received_discord_server_invitation_of(name, "indonesian"), do: "Menerima undangan dari server perselisihan #{name}. "
  def received_discord_server_invitation_of(name, _),            do: __MODULE__.received_discord_server_invitation_of(name, @default_lang)
end
