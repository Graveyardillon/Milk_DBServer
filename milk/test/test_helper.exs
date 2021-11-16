ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Milk.Repo, {:shared, self()})
Milk.Tournaments.Progress.flushall()
IO.puts("Test Helper has been completed")
