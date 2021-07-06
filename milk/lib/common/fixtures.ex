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

        capacity = opts[:capacity]
          |> is_nil()
          |> unless do
            opts[:capacity]
          else
            create_attrs["capacity"]
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

        team_size = if is_team do
            opts[:team_size]
            |> is_nil()
            |> unless do
              opts[:team_size]
            else
              5
            end
          else
            nil
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
          |> Map.put("capacity", capacity)
          |> Map.put("team_size", team_size)
          |> Tournaments.create_tournament()

        tournament
      end

      def fixture_user(opts \\ []) do
        num_str =
          opts[:num]
          |> is_nil()
          |> unless do
            to_string(opts[:num])
          else
            "0"
          end

        {:ok, user} =
          Accounts.create_user(%{
            "name" => "name" <> num_str,
            "email" => "e1" <> num_str <> "mail.com",
            "password" => "Password123"
          })

        user
      end
    end
  end
end
