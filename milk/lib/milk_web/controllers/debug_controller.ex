defmodule MilkWeb.DebugController do
  use MilkWeb, :controller

  @doc """
  Start a observer
  """
  def observe(conn, _params) do
    :observer.start()
    json(conn, %{msg: "observer started."})
  end
end
