ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Milk.Repo, {:shared, self()})
Milk.Tournaments.Progress.flushall()
