defmodule Milk.Common.Fixtures do
  alias Milk.{
    Accounts,
    Platforms,
    Tournaments
  }

  defmacro __using__(_opts) do
    quote do
      def fixture_tournament(opts \\ []) do
        Platforms.create_basic_platforms()

        create_attrs = %{
          "capacity" => 42,
          "deadline" => "2010-04-17T14:00:00Z",
          "description" => "some description",
          "event_date" => "2010-04-17T14:00:00Z",
          "master_id" => 42,
          "name" => "some name",
          "game_name" => "gm nm",
          "type" => 1,
          "join" => "true",
          "url" => "some url",
          "password" => "Password123",
          "platform" => 1
        }

        num = opts[:num]
          |> is_nil()
          |> unless do
            opts[:num]
          else
            0
          end

        is_started = opts[:is_started]
          |> is_nil()
          |> unless do
            opts[:is_started]
          else
            false
          end

        is_team = opts[:is_team]
          |> is_nil()
          |> unless do
            opts[:is_team]
          else
            false
          end

        master_id = opts[:master_id]
          |> is_nil()
          |> unless do
            opts[:master_id]
          else
            {:ok, user} =
              Accounts.create_user(%{
                "name" => "#{num}nname",
                "email" => "ee#{num}@mail.com",
                "password" => "Password123"
              })

            user.id
          end

        {:ok, tournament} =
          create_attrs
          |> Map.put("is_started", is_started)
          |> Map.put("master_id", master_id)
          |> Map.put("is_team", is_team)
          |> Tournaments.create_tournament()

        tournament
      end
    end
  end
end
