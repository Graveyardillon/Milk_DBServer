defmodule MilkWeb.AssistantController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  # action_fallback MilkWeb.FallbackController

  @doc """
  Return list of assistants.
  """
  def index(conn, _params) do
    assistant = Tournaments.list_assistant()
    render(conn, "index.json", assistant: assistant)
    # いらない気がしたのでコメントアウトしました
    # if(assistant) do
    #   render(conn, "index.json", assistant: assistant)
    # else
    #   render(conn, "error.json", error: nil)
    # end
  end

  @doc """
  Create an assistant
  """
  def create(conn, %{"assistant" => assistant_params}) do
    unless is_nil(assistant_params["tournament_id"]) do
      case Tournaments.create_assistants(assistant_params) do
        :ok ->
          assistant = Tournaments.get_assistants(assistant_params["tournament_id"])
          render(conn, "index.json", assistant: assistant)

        {:ok, not_found_users} ->
          assistant = Tournaments.get_assistants(assistant_params["tournament_id"])

          render(conn, "error_string.json",
            data: %{data: assistant, error: "#{inspect(not_found_users, charlists: false)}" <> " not found"}
          )

        {:error, :tournament_not_found} ->
          render(conn, "error_string.json", data: %{data: nil, error: "tournament not found"})
      end
    else
      render(conn, "error_string.json", data: %{data: nil, error: "invalid request parameters"})
    end
  end

  def show(conn, %{"id" => id}) do
    assistant = Tournaments.get_assistant(id)

    if(assistant) do
      render(conn, "show.json", assistant: assistant)
    else
      render(conn, "error.json", error: nil)
    end
  end
end
