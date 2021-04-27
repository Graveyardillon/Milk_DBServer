defmodule Milk.DiscordWebhook do
  @moduledoc """
  Discord webhook.
  """

  @doc """
  Send a webhook notification.
  """
  def post_text(text) do
    url = "https://discord.com/api/webhooks/836661276460449862/RjC4AIzBHQiOc3QbXBkAuuMpumEccWxfecbQ545GIH4Y0XJYoux2D1H11_UxMP2CXCSO"

    HTTPoison.post(
      url,
      Jason.encode!(%{content: text}),
      "Content-Type": "application/json"
    )
  end
end
