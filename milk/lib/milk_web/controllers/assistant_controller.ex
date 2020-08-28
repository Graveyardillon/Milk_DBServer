defmodule MilkWeb.AssistantController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  alias Milk.Tournaments.Assistant

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    assistant = Tournaments.list_assistant()
    render(conn, "index.json", assistant: assistant)
  end

  def create(conn, %{"assistant" => assistant_params}) do
    with {:ok, %Assistant{} = assistant} <- Tournaments.create_assistant(assistant_params) do
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.assistant_path(conn, :show, assistant))
      |> render("show.json", assistant: assistant)
    end
  end

  def show(conn, %{"id" => id}) do
    assistant = Tournaments.get_assistant!(id)
    render(conn, "show.json", assistant: assistant)
  end

  def update(conn, %{"id" => id, "assistant" => assistant_params}) do
    assistant = Tournaments.get_assistant!(id)

    with {:ok, %Assistant{} = assistant} <- Tournaments.update_assistant(assistant, assistant_params) do
      render(conn, "show.json", assistant: assistant)
    end
  end

  def delete(conn, %{"id" => id}) do
    assistant = Tournaments.get_assistant!(id)

    with {:ok, %Assistant{}} <- Tournaments.delete_assistant(assistant) do
      send_resp(conn, :no_content, "")
    end
  end
end
