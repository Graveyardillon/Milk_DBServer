defmodule MilkWeb.ProfileController do
  use MilkWeb, :controller

  alias Common.FileUtils

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Profiles,
    Tournaments
  }

  alias Milk.Media.Image
  alias Milk.CloudStorage.Objects

  action_fallback MilkWeb.FallbackController

  def get_profile(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Accounts.get_user()
    ~> user
    |> if do
      games = Profiles.get_game_list(user)
      records = Profiles.get_records(user)

      external_services = Accounts.get_external_services(user_id)

      render(conn, "profile.json",
        user: user,
        games: games,
        records: records,
        external_services: external_services
      )
    else
      json(conn, %{result: false, error: "user not found"})
    end
  end

  def update(conn, %{"profile" => profile_params}) do
    profile_params
    |> Map.get("user_id")
    |> Accounts.get_user()
    ~> user
    |> is_nil()
    |> unless do
      gamelist = Map.get(profile_params, "gameList")
      records = Map.get(profile_params, "records")

      Accounts.update_user(user, profile_params)
      |> case do
        {:ok, user} ->
          Profiles.update_gamelist(user, gamelist)
          Profiles.update_recordlist(user, records)
          json(conn, %{result: true, profile_result: true})

        {:error, error} ->
          json(conn, %{result: false, error: "update failed"})
      end
    else
      json(conn, %{result: false, error: "user not found"})
    end
  end

  def update_icon(conn, %{"user_id" => user_id, "file" => image}) do
    update_icon(conn, %{"user_id" => user_id, "image" => image})
  end

  def update_icon(conn, %{"user_id" => user_id, "image" => image}) do
    user = Accounts.get_user(user_id)

    if user do
      uuid = SecureRandom.uuid()

      FileUtils.copy(image.path, "./static/image/profile_icon/#{uuid}.png")

      :milk
      |> Application.get_env(:environment)
      |> case do
        :dev -> update_account(user, uuid)
        :test -> update_account(user, uuid)
        _ -> update_account_prod(user, uuid)
      end
      ~> local_path

      json(conn, %{local_path: local_path})
    else
      json(conn, %{error: "user not found"})
    end
  end

  defp update_account(user, uuid) do
    Accounts.update_icon_path(user, "./static/image/profile_icon/#{uuid}.png")
    uuid
  end

  defp update_account_prod(user, uuid) do
    object = Objects.upload("./static/image/profile_icon/#{uuid}.png")
    File.rm("./static/image/profile_icon/#{uuid}.png")
    Accounts.update_icon_path(user, object.name)
    object.name
  end

  def get_icon(conn, %{"path" => path}) do
    if path != "" do
      :milk
      |> Application.get_env(:environment)
      |> case do
        :dev -> get_image(path)
        :test -> get_image(path)
        _ -> get_image_prod(path)
      end
      |> case do
        {:ok, file} ->
          b64 = Base.encode64(file)
          json(conn, %{b64: b64})

        {:error, _} ->
          json(conn, %{error: "image not found"})
      end
    else
      json(conn, %{error: "path nil"})
    end
  end

  defp get_image(path) do
    File.read(path)
  end

  defp get_image_prod(name) do
    object = Objects.get(name)
    Image.get(object.mediaLink)
  end

  def records(conn, %{"user_id" => user_id}) do
    records = Tournaments.get_all_tournament_records(user_id)
    render(conn, "records.json", records: records)
  end

  def external_services(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Accounts.get_external_services()
    ~> external_services

    render(conn, "external_services.json", external_services: external_services)
  end
end
