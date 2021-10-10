defmodule MilkWeb.CheckController do
  use MilkWeb, :controller

  @doc """
  Check if server is available.
  """
  def connection_check(conn, _params) do
    json(conn, %{result: true})
  end
end
