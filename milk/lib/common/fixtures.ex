defmodule Common.Fixtures do
  alias Milk.{
    Accounts,
    Discord,
    Platforms,
    Tournaments
  }

  import Common.Sperm

  defmacro __using__(_opts) do
    quote do
      def fixture_tournament(opts \\ []) do
        Platforms.create_basic_platforms()

        create_attrs = %{
          "capacity" => 8,
          "deadline" => "2010-04-17T14:00:00Z",
          "description" => "some description",
          "event_date" => "2010-04-17T14:00:00Z",
          "name" => "some name",
          "game_name" => "gm nm",
          "type" => 1,
          "join" => "true",
          "url" => "some url",
          "password" => "Password123",
          "platform" => 1
        }

        num = Keyword.get(opts, :num, 0)
        deadline = Keyword.get(opts, :deadline, create_attrs["deadline"])
        capacity = Keyword.get(opts, :capacity, create_attrs["capacity"])
        is_started = Keyword.get(opts, :is_started, false)
        is_team = Keyword.get(opts, :is_team, false)
        team_size = if is_team, do: Keyword.get(opts, :team_size, 5)
        type = Keyword.get(opts, :type, 1)
        enabled_coin_toss = Keyword.get(opts, :enabled_coin_toss, false)
        enabled_map = Keyword.get(opts, :enabled_map, false)
        coin_head_field = Keyword.get(opts, :coin_head_field)
        coin_tail_field = Keyword.get(opts, :coin_tail_field)
        maps = Keyword.get(opts, :maps)
        deadline = Keyword.get(opts, :deadline)
        event_date = Keyword.get(opts, :event_date)

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
        ~> master_id

        create_attrs
        |> Map.put("is_started", is_started)
        |> Map.put("master_id", master_id)
        |> Map.put("is_team", is_team)
        |> Map.put("capacity", capacity)
        |> Map.put("team_size", team_size)
        |> Map.put("type", type)
        |> Map.put("deadline", deadline)
        |> Map.put("enabled_coin_toss", enabled_coin_toss)
        |> Map.put("enabled_map", enabled_map)
        |> Map.put("coin_head_field", coin_head_field)
        |> Map.put("coin_tail_field", coin_tail_field)
        |> Map.put("maps", maps)
        |> Map.put("deadline", deadline)
        |> Map.put("event_date", event_date)
        |> Tournaments.create_tournament()
        |> elem(1)
        ~> tournament

        tournament
      end

      # FIXME: 招待が二重で作成されている
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
        opts[:num]
        |> is_nil()
        |> unless do
          to_string(opts[:num])
        else
          "0"
        end
        ~> num_str

        Accounts.create_user(%{
          "name" => "name" <> num_str,
          "email" => "e1" <> num_str <> "mail.com",
          "password" => "Password123"
        })
        ~> {:ok, user}

        user
      end

      def fixture_discord_user(opts \\ []) do
        opts[:num]
        |> is_nil()
        |> unless do
          to_string(opts[:num])
        else
          "0"
        end
        ~> num

        user = fixture_user(num: num)

        discord_id = to_string(num)

        %{user_id: user.id, discord_id: discord_id}
        |> Discord.create_discord_user()
        ~> {:ok, discord_user}

        discord_user
      end
    end
  end
end
