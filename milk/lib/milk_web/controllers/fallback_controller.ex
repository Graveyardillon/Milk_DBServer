defmodule MilkWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  import Ecto.Changeset
  use MilkWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    IO.inspect "aaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(MilkWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(MilkWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, changeset}) do
    conn
    |> put_status(:not_found)
    |> put_view(MilkWeb.ErrorView)
    |> render(:"404")
  end


end
