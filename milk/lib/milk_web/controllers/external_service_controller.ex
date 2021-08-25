defmodule MilkWeb.ExternalServiceController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Milk.Accounts

  def create(conn, %{"user_id" => user_id, "name" => name, "content" => content}) do
    %{user_id: user_id, name: name, content: content}
    |> Accounts.create_external_service()
    |> elem(1)
    ~> external_service

    render(conn, "show.json", external_service: external_service)
  end

  def delete(conn, %{"id" => id}) do

  end
end
