use Timex

defmodule Spare do
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
|> IO.inspect()
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
|> IO.inspect(limit: :infinity)

1..25
|> Enum.to_list()
|> Enum.map(fn n ->
  Task.async(fn ->
    tournament_id = n

  end)
end)
|> Task.yield_many()
|> Enum.map(fn {task, res} ->
  res || Task.shutdown(task, :brutal_kill)
end)

Process.sleep(3000)

url = "http://localhost:4000/api/load_test/stop"
HTTPoison.post(url, Jason.encode!(%{}), "Content-Type": "application/json")
