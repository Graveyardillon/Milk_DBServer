use Timex

defmodule Spare do
  def get(url, attr) do
    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.get(
        url,
        [{"Content-Type", "application/json"}],
        params: attr
      )
    inspect(body, label: :body, charlists: false)
    with {:ok, map} <- Poison.decode(body) do
      map
    else
      e -> IO.inspect(e)
    end
  end

  def send_post(url, attr) do
    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post(
        url,
        Jason.encode!(attr),
        "Content-Type": "application/json"
      )
    {:ok, map} = Poison.decode(body)
    map
  end

  def state_process(state, user_id, tournament_id)
  when state != "IsLoser" and state != "IsFinished" do
    cond do
      state == "IsInMatch" ->
        "http://localhost:4000/api/tournament/start_match"
        |> send_post(%{"tournament_id" => tournament_id, "user_id" => user_id})
        |> IO.inspect(label: :start_match, charlists: false)

        Process.sleep(500)
      state == "IsAlone" ->
        Process.sleep(3000)
        state
      state == "IsWaitingForStart" ->
        Process.sleep(3000)
        IO.inspect("waiting...", charlists: false)
        state
      state == "IsPending" ->
        opponent_id = "http://localhost:4000/api/tournament/get_opponent"
          |> get(%{"tournament_id" => tournament_id, "user_id" => user_id})
          |> Map.get("opponent")
          |> Map.get("id")

        score = :rand.uniform(100000)

        "http://localhost:4000/api/tournament/claim_score"
        |> send_post(
          %{
            "tournament_id" => tournament_id,
            "user_id" => user_id,
            "opponent_id" => opponent_id,
            "score" => score,
            "match_index" => 0
          }
        )
        Process.sleep(500)
      true ->
        IO.inspect(state, charlists: false)
        state
    end

    Process.sleep(500)

    "http://localhost:4000/api/tournament/state"
    |> Spare.get(%{"tournament_id" => tournament_id, "user_id" => user_id})
    |> Map.put("user_id", user_id)
    |> Map.put("tournament_id", tournament_id)
    |> IO.inspect(label: :state, charlists: false)
    |> Map.get("state")
    |> state_process(user_id, tournament_id)
  end

  def state_process(state, _user_id, _tournament_id) do
    "end"
  end
end

url = "http://localhost:4000/api/load_test/start"
HTTPoison.post(url, Jason.encode!(%{}), "Content-Type": "application/json")

Process.sleep(1000)

1..25
|> Enum.to_list()
|> Enum.map(fn n ->
  url = "http://localhost:4000/api/user/signup"
  attr = %{
    "email" => to_string(n)<>"organizer@mail.co.m",
    "password" => "Password123",
    "name" => to_string(n)<>"organizer123"
  }
  Spare.send_post(url, %{"user" => attr})
end)
|> Enum.map(fn response ->
  now = Timex.now()
  tomorrow = Timex.now()
    |> Timex.add(Timex.Duration.from_days(1))
    |> Timex.to_datetime()

  master_id = response["data"]["id"]
  attrs = %{
    "master_id" => master_id,
    "capacity" => 4,
    "deadline" => tomorrow,
    "description" => "awesome tournament",
    "event_date" => tomorrow,
    "name" => "test tournament size 4",
    "type" => 2,
    "url" => nil,
    "thumbnail_path" => nil,
    "password" => nil,
    "game_name" => "my awesome name",
    "start_recruiting" => now,
    "platform" => 1,
    "game_id" => nil,
    "join" => false
  }
  |> Poison.encode!()
  form = [{"file", ""}, {"tournament", attrs}]
  {:ok, %HTTPoison.Response{body: body}} =
    HTTPoison.post(
      "http://localhost:4000/api/tournament",
      {:multipart, form},
      [{"Content-Type", "multipart/form-data"}],
      ssl: [{:versions, [:'tlsv1.2']}]
    )
  {:ok, map} = Poison.decode(body)
end)

users =
  1..100
  |> Enum.to_list()
  |> Enum.map(fn n ->
    url = "http://localhost:4000/api/user/signup"
    attr = %{
      "email" => to_string(n)<>"entrant@mail.co.m",
      "password" => "Password123",
      "name" => to_string(n)<>"participant123"
    }

    {n, Spare.send_post(url, %{"user" => attr})}
  end)

users
|> Enum.map(fn {n, response} ->
  0..24
  |> Enum.to_list()
  |> Enum.reduce([], fn m, acc ->
    if rem(n, 25) == m do
      url = "http://localhost:4000/api/entrant"
      attr = %{
        "tournament_id" => m+1,
        "user_id" => response["data"]["id"],
      }

      acc ++ Spare.send_post(url, %{"entrant" => attr})
    else
      acc
    end
  end)
end)

1..1
|> Enum.to_list()
|> Enum.map(fn n ->
  Process.sleep(500)
  Task.async(fn ->
    tournament_id = n
    master_id = "http://localhost:4000/api/tournament/get"
      |> Spare.get(%{"tournament_id" => tournament_id})
      |> Map.get("data")
      |> Map.get("master_id")

    "http://localhost:4000/api/tournament/start"
    |> Spare.send_post(
      %{"tournament" =>
        %{"tournament_id" => tournament_id, "master_id" => master_id}
      }
    )

    "http://localhost:4000/api/tournament/get_entrants"
    |> Spare.get(%{"tournament_id" => tournament_id})
    |> Map.get("data")
    |> IO.inspect(label: :data, charlists: false)
    |> Enum.map(fn %{"user_id" => user_id} ->
      IO.inspect(user_id, label: :user_id, charlists: false)
      Process.sleep(500)
      Task.async(fn ->
        "http://localhost:4000/api/tournament/state"
        |> Spare.get(%{"tournament_id" => tournament_id, "user_id" => user_id})
        |> Map.get("state")
        |> Spare.state_process(user_id, tournament_id)
        |> IO.inspect(label: :end, charlists: false)
      end)
    end)
  end)
end)
# |> Task.yield_many(:infinity)
# |> Enum.map(fn {task, res} ->
#   #res || Task.shutdown(task, :brutal_kill)
# end)

Process.sleep(3600000)

url = "http://localhost:4000/api/load_test/stop"
HTTPoison.post(url, Jason.encode!(%{}), "Content-Type": "application/json")
