defmodule Milk.UserManager.GuardianPipeline do
  use MilkWeb, :controller

  import Plug.Conn

  alias Milk.UserManager.Guardian

  def init(default), do: default

  def call(%Plug.Conn{params: %{"token" => token}} = conn, _default) do
    token
    |> Guardian.decode_and_verify()
    |> case do
      {:ok, _} ->
        conn

      {:error, :token_expired} ->
        Guardian.signout(token)
        |> if do
          conn
          |> json(%{result: false, error: "That token is out of time"})
          |> put_status(500)
          |> halt()
        else
          conn
          |> json(%{result: false, error: "That token does not exist"})
          |> put_status(500)
          |> halt()
        end

      {:error, :not_exist} ->
        conn
        |> json(%{result: false, error: "That token can't use"})
        |> put_status(500)
        |> halt()

      _ ->
        conn
        |> json(%{result: false, error: "That token does not exist"})
        |> put_status(500)
        |> halt()
    end
  end

  def call(conn, _default) do
    if(
      String.contains?(conn.request_path, "api/user/login") or
        String.contains?(conn.request_path, "api/user/signup") or
        String.contains?(conn.request_path, "api/user/signin") or
        String.contains?(conn.method, "GET") or
        String.contains?(conn.request_path, "api/chat/create_dialogue") or
        String.contains?(conn.request_path, "api/notification/create") or
        String.contains?(conn.request_path, "api/conf/send_email") or
        String.contains?(conn.request_path, "api/conf/conf_email")
    ) do
      conn
    else
      conn
      |> json(%{result: false, error: "There's not a token"})
      |> put_status(500)
      |> halt()
    end
  end
end
