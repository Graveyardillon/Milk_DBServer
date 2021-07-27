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
          json(conn, %{result: false, error: "That token is out of time"})
          halt(conn)
        else
          json(conn, %{result: false, error: "That token does not exist"})
          halt(conn)
        end

      {:error, :not_exist} ->
        json(conn, %{result: false, error: "That token can't use"})
        halt(conn)

      _ ->
        json(conn, %{result: false, error: "That token does not exist"})
        halt(conn)
    end
  end

  def call(conn, _default) do
    if(
      String.contains?(conn.request_path, "api/user/login") or
      String.contains?(conn.request_path, "api/user/signup") or
      String.contains?(conn.request_path, "api/user/signin") or
      String.contains?(conn.method, "GET") or
      String.contains?(conn.request_path, "api/chat/create_dialogue") or
      String.contains?(conn.request_path, "api/notification/create")
    ) do
      conn
    else
      IO.inspect(conn, label: :call_conn)
      json(conn, %{result: false, error: "There's not a token"})
      halt(conn)
    end
  end
end
