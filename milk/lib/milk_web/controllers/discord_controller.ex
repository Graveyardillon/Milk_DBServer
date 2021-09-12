defmodule MilkWeb.DiscordController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Milk.Discord

  def associate(conn, %{"user_id" => user_id, "discord_id" => discord_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Discord.associate(discord_id)
    |> IO.inspect()
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end
end
