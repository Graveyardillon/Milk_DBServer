use Timex

url = "http://localhost:4000/api/load_test/start"
HTTPoison.post(url, Jason.encode!(%{}), "Content-Type": "application/json")

Process.sleep(1000)

1..25
|> Enum.to_list()
|> Enum.map(fn n ->
  attr = %{
    "email" => to_string(n)<>"organizer@mail.co.m",
    "password" => "Password123",
    "name" => to_string(n)<>"organizer123"
  }
  {:ok, %HTTPoison.Response{body: body}} =
    HTTPoison.post(
      "http://localhost:4000/api/user/signup",
      Jason.encode!(%{"user" => attr}),
      "Content-Type": "application/json"
    )
  {:ok, map} = Poison.decode(body)
  map
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
    attr = %{
      "email" => to_string(n)<>"entrant@mail.co.m",
      "password" => "Password123",
      "name" => to_string(n)<>"participant123"
    }

    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post(
        "http://localhost:4000/api/user/signup",
        Jason.encode!(%{"user" => attr}),
        "Content-Type": "application/json"
      )
    {:ok, map} = Poison.decode(body)
    {n, map}
  end)

users
|> Enum.map(fn {n, response} ->
  0..25
  |> Enum.to_list()
  |> Enum.reduce(nil, fn m, acc ->
    if rem(n, 25) == m do
      attr = %{
        "tournament_id" => m,
        "user_id" => n,
      }

      {:ok, %HTTPoison.Response{body: body}} =
        HTTPoison.post(
          "http://localhost:4000/api/entrant",
          Jason.encode!(%{"entrant" => attr}),
          "Content-Type": "application/json"
        )
      {:ok, map} = Poison.decode(body)
      map
    else
      acc
    end
  end)
end)
|> IO.inspect()

Process.sleep(3000)

url = "http://localhost:4000/api/load_test/stop"
HTTPoison.post(url, Jason.encode!(%{}), "Content-Type": "application/json")
