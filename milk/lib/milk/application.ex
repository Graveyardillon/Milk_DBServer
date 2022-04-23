defmodule Milk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # credentials = "e-players6814-8e8eac82841c.json" |> File.read! |> Jason.decode!()
    credentials = :milk
      |> Application.get_env(:json_file)
      |> Jason.decode!()
    source = {:service_account, credentials, []}

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Milk.Repo,
      # Start the endpoint when the application starts
      MilkWeb.Endpoint,
      {Phoenix.PubSub, [name: Milk.PubSub, adapter: Phoenix.PubSub.PG2]},
      {Task, fn -> Milk.setup_platform() end},
      Milk.ConfNum,
      Milk.Email.Auth,
      # Common.KeyValueStore,
      {Goth, name: Milk.Goth, source: source},
      {Oban, oban_config()},
      Milk.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Milk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MilkWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:milk, Oban)
  end
end
