defmodule MilkWeb.AssistantController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  alias Milk.Tournaments.Assistant

  # action_fallback MilkWeb.FallbackController

  @doc """
  Return list of assistants.
  """
  def index(conn, _params) do
    assistant = Tournaments.list_assistant()
    if(assistant) do
      render(conn, "index.json", assistant: assistant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Create an assistant
  """
  def create(conn, %{"assistant" => assistant_params}) do
    unless is_nil(assistant_params["tournament_id"]) do
      case Tournaments.create_assistant(assistant_params) do
        :ok ->
          assistant = Tournaments.get_assistants(assistant_params["tournament_id"])
          render(conn, "index.json", assistant: assistant)

        {:ok, not_found_users} ->
          assistant = Tournaments.get_assistants(assistant_params["tournament_id"])
          render(conn, "error_string.json", data: %{data: assistant, error: "#{inspect(not_found_users)}" <> " not found"})

        {:error, :tournament_not_found} ->
          render(conn, "error_string.json", data: %{data: nil, error: "tournament not found"})
        _ ->
          render(conn, "error_string.json", data: %{data: nil, error: "invalid request parameters"})
      end
    else
      render(conn, "error_string.json", data: %{data: nil, error: "invalid request parameters"})
    end
  end

  def show(conn, %{"id" => id}) do
    assistant = Tournaments.get_assistant!(id)
    if(assistant) do
      render(conn, "show.json", assistant: assistant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"id" => id}) do
    assistant = Tournaments.get_assistant!(id)

    with {:ok, %Assistant{}} <- Tournaments.delete_assistant(assistant) do
      send_resp(conn, :no_content, "")
    end
  end
end
