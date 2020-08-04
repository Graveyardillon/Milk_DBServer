defmodule Milk.UserManager.GuardianPipline do
  use MilkWeb, :controller
  import Plug.Conn

  alias Milk.UserManager.Guardian
  

  def init(default), do: default

  def call(%Plug.Conn{params: %{"token" => token}} = conn, default) do
    case Guardian.decode_and_verify(token) do
      {:ok, _} ->
        conn
      {:error, :token_expired} ->
        Guardian.signout(token)
        |> if do
          json(conn, %{result: false, error: "That token is out of time"})
          halt(conn)
        else
          json(conn, %{result: false, error: "That token is not exist"})
          halt(conn)
        end
      {:error, :not_exist} ->
        json(conn, %{resutl: false, error: "That token can't use"})
        halt(conn)
      _ ->
        json(conn, %{result: false, error: "That token is not exist"})
        halt(conn)
    end
  end

  def call(conn, default) do
    if(String.contains?(conn.request_path, "login") or String.contains?(conn.request_path, "signup")) do
      conn
    else
      json(conn, %{result: false, error: "There's not a token"})
      halt(conn)
    end
  end
end