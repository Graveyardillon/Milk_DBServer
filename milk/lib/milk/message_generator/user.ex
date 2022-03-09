defmodule Milk.MessageGenerator.User do
  @moduledoc """
  多言語のメッセージを扱うためのやつ
  """

  @default_lang "english"

  def welcome_to_eplayers("japanese"),   do: "e-playersへようこそ！"
  def welcome_to_eplayers("english"),    do: "Welcome to e-players!"
  def welcome_to_eplayers("indonesian"), do: "Selamat datang di e-players"
  def welcome_to_eplayers(_),            do: __MODULE__.welcome_to_eplayers(@default_lang)

  def why_dont_you_join_us("japanese"),   do: "もしよければTwitterをフォローしてお知らせを受け取ってください！\n@e_player_s"
  def why_dont_you_join_us("english"),    do: "Please follow our twitter!\n@e_player_s"
  def why_dont_you_join_us("indonesian"), do: "Silahkan ikuti twitter kami\n@e_player_s"
  def why_dont_you_join_us(_),            do: __MODULE__.why_dont_you_join_us(@default_lang)
end
