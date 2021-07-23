defmodule Common.Fixtures do
  alias Milk.{
    Accounts,
    Platforms,
    Tournaments
  }

  import Common.Sperm

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

        num =
          opts[:num]
          |> is_nil()
          |> unless do
            opts[:num]
          else
            0
          end

        capacity =
          opts[:capacity]
          |> is_nil()
          |> unless do
            opts[:capacity]
          else
            create_attrs["capacity"]
          end

        is_started =
          opts[:is_started]
          |> is_nil()
          |> unless do
            opts[:is_started]
          else
            false
          end

        is_team =
          opts[:is_team]
          |> is_nil()
          |> unless do
            opts[:is_team]
          else
            false
          end

        team_size =
          if is_team do
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

        type =
          opts[:type]
          |> is_nil()
          |> unless do
            opts[:type]
          else
            1
          end

        master_id =
          opts[:master_id]
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
          |> Map.put("type", type)
          |> Tournaments.create_tournament()

        tournament
      end

      def fill_with_team(tournament_id) do
        tournament = Tournaments.get_tournament(tournament_id)

        101..(tournament.team_size * tournament.capacity + 100)
        |> Enum.to_list()
        |> Enum.map(fn n ->
          fixture_user(num: n)
        end)
        ~> users
        |> Enum.map(fn user ->
          user.id
        end)
        |> Enum.chunk_every(tournament.team_size)
        |> Enum.map(fn [leader | members] ->
          tournament.id
          |> Tournaments.create_team(tournament.team_size, leader, members)
          |> elem(1)
        end)
        |> Enum.map(fn team ->
          team.id
          |> Tournaments.get_team_members_by_team_id()
          |> Enum.each(fn member ->
            leader = Tournaments.get_leader(member.team_id)

            member.id
            |> Tournaments.create_team_invitation(leader.user_id)
            |> elem(1)
            |> Map.get(:id)
            |> Tournaments.confirm_team_invitation()
            |> elem(1)
          end)

          Tournaments.get_team(team.id)
        end)
      end

      def fill_with_entrant(tournament_id) do
        tournament = Tournaments.get_tournament(tournament_id)

        101..(tournament.capacity + 100)
        |> Enum.to_list()
        |> Enum.map(fn n ->
          [num: n]
          |> fixture_user()
          |> Map.get(:id)
        end)
        |> Enum.map(fn user_id ->
          Map.new()
          |> Map.put("user_id", user_id)
          |> Map.put("tournament_id", tournament_id)
          |> Tournaments.create_entrant()
          |> elem(1)
        end)
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
