defmodule MilkWeb.ExternalServiceController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.Accounts

  def create(conn, %{"user_id" => user_id, "name" => name, "content" => content}) do
    %{user_id: user_id, name: name, content: content}
    |> Accounts.create_external_service()
    |> elem(1)
    ~> external_service

    render(conn, "show.json", external_service: external_service)
  end

  def delete(conn, %{"id" => id}) do
    id
    |> Tools.to_integer_as_needed()
    |> Accounts.delete_external_service()
    |> case do
      {:ok, service} ->
        render(conn, "show.json", external_service: service)
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end
end
