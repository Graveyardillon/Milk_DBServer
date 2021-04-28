defmodule Milk.DiscordWebhook do
  @moduledoc """
  Discord webhook.
  """

  @doc """
  Send a webhook notification.
  """
  def post_text_to_user_report_channel(text) do
    url = "https://discord.com/api/webhooks/836661276460449862/RjC4AIzBHQiOc3QbXBkAuuMpumEccWxfecbQ545GIH4Y0XJYoux2D1H11_UxMP2CXCSO"

    HTTPoison.post(
      url,
      Jason.encode!(%{content: text}),
      "Content-Type": "application/json"
    )
  end

  def post_text_to_tournament_report_channel(text) do
    url = "https://discord.com/api/webhooks/836668214670524475/2QYQQAfZNp_AVvOmy_igefCK0h0LTqQvEmAWtiZwDYgO-aciiYgwr1v0oCsNJiZn3YR-"

    HTTPoison.post(
      url,
      Jason.encode!(%{content: text}),
      "Content-Type": "application/json"
    )
  end
end
