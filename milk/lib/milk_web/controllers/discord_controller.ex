defmodule MilkWeb.DiscordController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.{
    Accounts,
    Discord,
    Notif,
    Tournaments
  }

  def team_name(conn, %{"discord_user_id" => discord_user_id, "discord_server_id" => discord_server_id}) do
    discord_user_id
    |> Accounts.get_user_by_discord_id()
    ~> user

    discord_server_id
    |> Tournaments.get_tournament_by_discord_server_id()
    ~> tournament

    team = Tournaments.get_team_by_tournament_id_and_user_id(tournament.id, user.id)

    json(conn, %{result: true, team_name: team.name})
  end

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

  def resend_invitation_links(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_team()
    |> Map.get(:tournament_id)
    |> Tournaments.get_tournament()
    ~> tournament

    invitation_link = Discord.create_invitation_link!(tournament.discord_server_id)

    team_id
    |> Tournaments.get_team_members_by_team_id()
    |> Enum.each(fn member ->
      %{
        "user_id" => member.user_id,
        "process_id" => "DISCORD_SERVER_INVITATION",
        "icon_path" => tournament.thumbnail_path,
        "title" => "#{tournament.name}のDiscordサーバーへの招待を受け取りました",
        "body_text" => "",
        "data" => Jason.encode!(%{
          url: invitation_link
        })
      }
      |> Notif.create_notification()
    end)
    |> case do
      :ok -> json(conn, %{result: true})
      _ -> render(conn, "error.json", error: nil)
    end
  end
end
