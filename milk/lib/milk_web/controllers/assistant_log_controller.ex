defmodule MilkWeb.AssistantLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.AssistantLog

  #action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    assistant_log = Log.list_assistant_log()
    render(conn, "index.json", assistant_log: assistant_log)
  end

  def create(conn, %{"data" => assistant_log_params}) do

    with {:ok, %AssistantLog{} = assistant_log} <- Log.create_assistant_log(assistant_log_params) do
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.assistant_log_path(conn, :show, assistant_log))
      json(conn, assistant_log)
      #render(conn, "show.json", assistant_log: assistant_log)
    end
  end

  def show(conn, %{"id" => id}) do
    assistant_log = Log.get_assistant_log!(id)
    render(conn, "show.json", assistant_log: assistant_log)
  end

  def update(conn, %{"id" => id, "assistant_log" => assistant_log_params}) do
    assistant_log = Log.get_assistant_log!(id)

    with {:ok, %AssistantLog{} = assistant_log} <- Log.update_assistant_log(assistant_log, assistant_log_params) do
      render(conn, "show.json", assistant_log: assistant_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    assistant_log = Log.get_assistant_log!(id)

    with {:ok, %AssistantLog{}} <- Log.delete_assistant_log(assistant_log) do
      send_resp(conn, :no_content, "")
    end
  end
end
