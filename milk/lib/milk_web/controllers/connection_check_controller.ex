defmodule MilkWeb.ConnectionCheckController do
  use MilkWeb, :controller

  @doc """
  Check if server is available.
  """
  def connection_check(conn, _parmas) do
    json(conn, %{result: true})
  end
end
