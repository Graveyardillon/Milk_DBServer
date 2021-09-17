defmodule MilkWeb.DiscordController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.{
    Discord,
    Tournaments
  }

  def associate(conn, %{"user_id" => user_id, "discord_id" => discord_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Discord.associate(discord_id)
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  def dissociate(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Discord.get_discord_user_by_user_id()
    |> Discord.delete_discord_user()
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  def create_invitation_link(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tournament()
    |> Map.get(:discord_server_id)
    ~> discord_server_id

    access_token = Application.get_env(:milk, :discord_server_access_token)
    url = "#{Application.get_env(:milk, :discord_server)}/invitation_link"

    params = Jason.encode!(%{server_id: discord_server_id, access_token: access_token})

    url
    |> HTTPoison.post(params, "Content-Type": "application/json")
    |> case do
      {:ok, response} ->
        response
        |> Map.get(:body)
        |> Jason.decode()
        ~> {:ok, json}

        json(conn, %{result: true, url: json["url"]})
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end
end
