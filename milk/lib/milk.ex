defmodule Milk do
  @moduledoc """
  Milk keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  Program around TCP Server.
  It only connects Pappap Webserver.
  """

  alias Milk.Platforms

  def setup_platform() do
    Platforms.create_basic_platforms()
  end
end
