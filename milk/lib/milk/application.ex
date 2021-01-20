defmodule Milk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Milk.Repo,
      # Start the endpoint when the application starts
      MilkWeb.Endpoint,
      {Phoenix.PubSub, [name: Milk.PubSub, adapter: Phoenix.PubSub.PG2]},
      {Task, fn -> Milk.setup_platform() end},
      Milk.ConfNum,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Milk.Ets.create_match_list_table()
    Milk.Ets.create_match_list_with_fight_result_table()
    Milk.Ets.create_match_pending_list_table()
    Milk.Ets.create_fight_result_table()
    opts = [strategy: :one_for_one, name: Milk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MilkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
