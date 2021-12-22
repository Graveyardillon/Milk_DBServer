defmodule Milk.UserManager.GuardianPipeline do
  use MilkWeb, :controller

  import Plug.Conn

  alias Milk.UserManager.Guardian

  def init(default), do: default

  def call(%Plug.Conn{params: %{"token" => token}} = conn, _default) do
    if !check_guardian_routing(conn) do
      token
      |> Guardian.decode_and_verify()
      |> case do
        {:ok, _} ->
          conn

        {:error, :token_expired} ->
          token
          |> Guardian.signout()
          |> if do
            conn
            |> put_status(401)
            |> json(%{result: false, error: "That token is out of time"})
            |> halt()
          else
            conn
            |> put_status(401)
            |> json(%{result: false, error: "That token does not exist"})
            |> halt()
          end

        {:error, :not_exist} ->
          conn
          |> put_status(401)
          |> json(%{result: false, error: "That token can't use"})
          |> halt()

        _ ->
          conn
          |> put_status(401)
          |> json(%{result: false, error: "That token does not exist"})
          |> halt()
      end
    else
      conn
    end
  end

  def call(conn, _default) do
    if check_guardian_routing(conn) do
      conn
    else
      conn
      |> put_status(401)
      |> json(%{result: false, error: "There's not a token"})
      |> halt()
    end
  end

  defp check_guardian_routing(conn) do
    String.contains?(conn.method, "GET") or
      String.contains?(conn.request_path, "api/user/login") or
      String.contains?(conn.request_path, "api/user/signup") or
      String.contains?(conn.request_path, "api/user/signin") or
      String.contains?(conn.request_path, "api/user/logout") or
      String.contains?(conn.request_path, "api/user/signin_with_discord") or
      String.contains?(conn.request_path, "api/user/signin_with_apple") or
      String.contains?(conn.request_path, "api/chat/create_dialogue") or
      String.contains?(conn.request_path, "api/notification/create") or
      String.contains?(conn.request_path, "api/conf/send_email") or
      String.contains?(conn.request_path, "api/conf/conf_email") or
      # FIXME: 取り置きの処理。 discordからのリクエストのときのみ、tokenを無効化したい。
      String.contains?(conn.request_path, "api/tournament/claim_win") or
      String.contains?(conn.request_path, "api/tournament/claim_lose")
  end
end
